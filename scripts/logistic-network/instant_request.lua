-- scripts/logistic-network/instant_request.lua
-- Instant Request

local M = {}

-- --------------------------------------------------------------------------------
-- Storage keys
-- --------------------------------------------------------------------------------

local ENABLED_KEY = "facc_instant_request_enabled"   -- boolean (global toggle)
local ENTITY_LIST_KEY = "facc_instant_request_entities" -- array of unit_numbers
local RR_INDEX_KEY = "facc_instant_request_rr_index" -- round-robin index

-- --------------------------------------------------------------------------------
-- Storage helpers
-- --------------------------------------------------------------------------------

--- Ensures storage keys exist with sane defaults.
local function ensure_storage()
  storage[ENABLED_KEY] = storage[ENABLED_KEY] or false
  storage[ENTITY_LIST_KEY] = storage[ENTITY_LIST_KEY] or {}
  storage[RR_INDEX_KEY] = storage[RR_INDEX_KEY] or 1
end

--- Returns whether the feature is globally enabled.
local function is_enabled()
  ensure_storage()
  return storage[ENABLED_KEY] == true
end

--- Returns the current list of tracked entity unit_numbers.
local function get_entity_list()
  ensure_storage()
  return storage[ENTITY_LIST_KEY]
end

-- --------------------------------------------------------------------------------
-- Entity management
-- --------------------------------------------------------------------------------

--- Returns true if the entity is one we can instantly fulfill requests for.
--- Includes characters, spider vehicles, vanilla tank, requester/buffer chests,
--- and the Space Platform Hub (type "space-platform-hub").
local function is_supported_entity(ent)
  if not (ent and ent.valid and ent.force and ent.force.name == "player") then return false end
  local t = ent.type
  if t == "character" then return true end
  if t == "spider-vehicle" then return true end
  if t == "car" and ent.name == "tank" then return true end
  if t == "logistic-container" then
    local mode = ent.prototype and ent.prototype.logistic_mode
    return mode == "requester" or mode == "buffer"
  end
  -- Space Age: Space Platform Hub
  if t == "space-platform-hub" then return true end
  return false
end

--- Adds an entity (by unit_number) to the tracked list (idempotent).
local function add_entity(ent)
  if not (ent and ent.valid and ent.unit_number) then return end
  local list = get_entity_list()
  for _, un in ipairs(list) do
    if un == ent.unit_number then return end
  end
  table.insert(list, ent.unit_number)
end

--- Removes an entity (by unit_number) from the tracked list.
local function remove_entity(ent)
  local un = ent and ent.unit_number
  if not un then return end
  local list = get_entity_list()
  for i, v in ipairs(list) do
    if v == un then
      table.remove(list, i)
      break
    end
  end
end

--- Rebuilds the tracked entity list by scanning all surfaces for supported entities.
local function refresh_entity_list()
  local new_list = {}
  for _, s in pairs(game.surfaces) do
    for _, ent in pairs(s.find_entities_filtered{force = "player"}) do
      if is_supported_entity(ent) then
        table.insert(new_list, ent.unit_number)
      end
    end
  end
  storage[ENTITY_LIST_KEY] = new_list
end

-- --------------------------------------------------------------------------------
-- Low-level helpers (safe accessors)
-- --------------------------------------------------------------------------------

--- Internal helper: normalize a get_logistic_point() return value into a single requester point.
--- Accepts either a LuaLogisticPoint or a table (list) of points.
local function pick_requester_point(val)
  -- Case 1: single point object
  local ok_obj, objname = pcall(function() return val.object_name end)
  if ok_obj and objname == "LuaLogisticPoint" then
    return val
  end
  -- Case 2: a table/array of points; pick the one with requester mode
  if type(val) == "table" then
    for _, p in pairs(val) do
      local ok_mode, mode = pcall(function() return p.mode end)
      if ok_mode and mode == defines.logistic_mode.requester then
        return p
      end
    end
  end
  return nil
end

--- Returns the requester logistic point for the entity, or nil if none/disabled.
--- This is resilient to API differences:
--- * For known types we attempt a specific logistic_member_index.
--- * If the API returns multiple points (e.g. Space Platform Hub), we pick the requester by mode.
local function get_requester_point(ent)
  if not (ent and ent.valid) then return nil end

  -- Select a likely member index for types that expose one.
  local index
  if ent.type == "character" then
    index = defines.logistic_member_index.character_requester
  elseif ent.type == "logistic-container" then
    index = defines.logistic_member_index.logistic_container
  elseif ent.type == "spider-vehicle" then
    index = defines.logistic_member_index.spidertron_requester
  elseif ent.type == "car" then
    -- Tank exposes a logistic container-like requester.
    index = defines.logistic_member_index.logistic_container
  elseif ent.type == "space-platform-hub" then
    -- Newer builds may expose a specific index for the hub; if not present, pass nil.
    index = (defines and defines.logistic_member_index and
            (defines.logistic_member_index.space_platform_hub
              or defines.logistic_member_index.space_platform_hub_requester))
            or nil
  end

  -- Fetch raw point(s)
  local ok_raw, raw = pcall(function() return ent.get_logistic_point(index) end)
  if not (ok_raw and raw) then return nil end

  -- Normalize to a single requester point
  local lp = pick_requester_point(raw)
  if not lp then return nil end

  -- Ignore if disabled
  local ok_en, en = pcall(function() return lp.enabled end)
  if ok_en and en == false then return nil end

  return lp
end

--- Iterates over active sections of a logistic point and invokes cb(section).
--- Tries multiple strategies to handle API variants (sections list, sections_count, get_section).
local function iter_active_sections(lp, cb)
  if not lp then return end

  -- Strategy A: property 'sections' as an array
  local ok_prop, sections = pcall(function() return lp.sections end)
  if ok_prop and type(sections) == "table" then
    for _, sec in ipairs(sections) do
      local ok_act, active = pcall(function() return sec.active end)
      if ok_act and active then cb(sec) end
    end
    return
  end

  -- Strategy B: numeric 'sections_count' and get_section(i)
  local ok_cnt, n = pcall(function() return lp.sections_count end)
  if ok_cnt and type(n) == "number" and n > 0 then
    for i = 1, n do
      local ok_gs, sec = pcall(function() return lp.get_section(i) end)
      if ok_gs and sec then
        local ok_act, active = pcall(function() return sec.active end)
        if ok_act and active then cb(sec) end
      end
    end
    return
  end

  -- Strategy C: blind probing up to a sane cap
  local i = 1
  while i <= 50 do
    local ok_gs, sec = pcall(function() return lp.get_section(i) end)
    if not ok_gs or not sec then break end
    local ok_act, active = pcall(function() return sec.active end)
    if ok_act and active then cb(sec) end
    i = i + 1
  end
end

--- Iterates over filters (slots) in a section and invokes cb(filter).
--- Supports both 'filters' array and numbered slots via get_slot(i).
local function iter_filters(section, cb)
  local ok, filters = pcall(function() return section.filters end)
  if ok and type(filters) == "table" then
    for _, f in ipairs(filters) do cb(f) end
    return
  end

  -- Fallback: numbered slots
  local i = 1
  while i <= 50 do
    local ok_s, slot = pcall(function() return section.get_slot(i) end)
    if not ok_s or not slot then break end
    cb(slot)
    i = i + 1
  end
end

-- --------------------------------------------------------------------------------
-- Refilling logic
-- --------------------------------------------------------------------------------

--- Converts a filter/slot into a requested item descriptor {name, min, quality} or nil.
local function extract_item_request(filter)
  local ok_v, value = pcall(function() return filter.value end)
  if not ok_v or not value then return nil end
  if value.type ~= "item" then return nil end

  local name = value.name
  if not name or name == "" then return nil end

  local req_min
  local ok_min, min_val = pcall(function() return filter.min end)
  if ok_min and type(min_val) == "number" then
    req_min = min_val
  else
    local ok_cnt, cnt = pcall(function() return filter.count end)
    req_min = (ok_cnt and tonumber(cnt)) or 0
  end

  local quality
  local ok_q, q = pcall(function() return value.quality end)
  if ok_q and q then quality = q end

  return { name = name, min = req_min or 0, quality = quality }
end

--- Counts how many of the given (name, quality) an entity currently holds.
local function total_count(ent, item_name, quality)
  local stack = { name = item_name }
  if quality then stack.quality = quality end
  local ok, n = pcall(function() return ent.get_item_count(stack) end)
  return (ok and tonumber(n)) or 0
end

--- Attempts to insert up to 'want' items (name, quality) into 'ent'.
--- Returns the number actually inserted (0 if none).
local function try_insert(ent, name, want, quality)
  if want <= 0 then return 0 end
  local stack = { name = name, count = want }
  if quality then stack.quality = quality end
  local ok, ins = pcall(function() return ent.insert(stack) end)
  return (ok and tonumber(ins)) or 0
end

--- Fulfills a single filter's request on 'ent' by inserting the missing amount, if any.
local function fulfill_filter(ent, filter)
  local req = extract_item_request(filter)
  if not req then return end
  local have = total_count(ent, req.name, req.quality)
  local need = (req.min or 0) - have
  if need > 0 then
    try_insert(ent, req.name, need, req.quality)
  end
end

--- Fulfills all active requests for an entity's requester logistic point.
local function fulfill_all_active_requests(ent)
  local lp = get_requester_point(ent)
  if not lp then return end
  iter_active_sections(lp, function(section)
    iter_filters(section, function(filter)
      fulfill_filter(ent, filter)
    end)
  end)
end

-- --------------------------------------------------------------------------------
-- Public API: toggle & event handlers
-- --------------------------------------------------------------------------------

--- Enables/disables the instant request feature globally.
--- When enabling, rebuilds the entity list; when disabling, clears it.
function M.toggle_player(player, enable)
  ensure_storage()
  storage[ENABLED_KEY] = (enable == true)
  if enable then
    refresh_entity_list()
  else
    storage[ENTITY_LIST_KEY] = {}
  end
  if player and player.valid then
    if enable then
      player.print({"facc.instant-request-enabled"})
    else
      player.print({"facc.instant-request-disabled"})
    end
  end
end

--- Handler for when a logistic slot changes on an entity that exposes sections (e.g., chests, hub).
--- If the section is active and we have a filter at e.slot_index, fulfills just that filter.
function M.on_entity_logistic_slot_changed(e)
  if not is_enabled() then return end
  local ent = e and e.entity
  if not (ent and ent.valid and ent.force and ent.force.name == "player" and is_supported_entity(ent)) then return end

  local sec = e.section
  local ok_act, active = pcall(function() return sec.active end)
  if not (ok_act and active) then return end

  local ok_slot, filter = pcall(function() return sec.get_slot(e.slot_index) end)
  if ok_slot and filter then
    fulfill_filter(ent, filter)
  end
end

--- Handler for when a player's main inventory changes (character logistics).
--- When enabled, immediately tops up any active requests for that character.
function M.on_player_main_inventory_changed(e)
  if not is_enabled() then return end
  local player = e and e.player_index and game.get_player(e.player_index) or nil
  if not (player and player.valid and player.character and player.character.valid) then return end
  fulfill_all_active_requests(player.character)
end

--- On-tick round-robin: each tick (when enabled) we service one tracked entity, if any.
function M.on_tick(_e)
  if not is_enabled() then return end
  local list = get_entity_list()
  if #list == 0 then return end

  local i = storage[RR_INDEX_KEY]
  if i > #list then i = 1 end

  local attempts = 0
  while attempts < #list do
    local un = list[i]
    local ent = game.get_entity_by_unit_number(un)
    if ent and ent.valid and is_supported_entity(ent) then
      fulfill_all_active_requests(ent)
      i = i + 1
      if i > #list then i = 1 end
      break
    else
      table.remove(list, i)
      if i > #list then i = 1 end
    end
    attempts = attempts + 1
  end

  storage[RR_INDEX_KEY] = i
end

-- --------------------------------------------------------------------------------
-- Event hooks for adding/removing entities (convenience wiring)
-- Note: Other events (on_tick, inventory/logistic slot changes) can be wired elsewhere if desired.
-- --------------------------------------------------------------------------------

script.on_event(
  { defines.events.on_built_entity
  , defines.events.on_robot_built_entity
  , defines.events.script_raised_built
  },
  function(e)
    if not is_enabled() then return end
    local ent = e.created_entity or e.entity
    if is_supported_entity(ent) then
      add_entity(ent)
    end
  end
)

script.on_event(
  { defines.events.on_entity_died
  , defines.events.on_robot_mined_entity
  , defines.events.on_player_mined_entity
  , defines.events.script_raised_destroy
  },
  function(e)
    if not is_enabled() then return end
    local ent = e.entity
    remove_entity(ent)
  end
)

return M
