-- scripts/logistic-network/instant_request.lua
-- Instant Request

local M = {}

-- --------------------------------------------------------------------------------
-- Storage keys
-- --------------------------------------------------------------------------------

local ENABLED_KEY = "facc_instant_request_enabled"      -- boolean (global toggle)
local ENTITY_LIST_KEY = "facc_instant_request_entities" -- array of unit_numbers
local RR_INDEX_KEY = "facc_instant_request_rr_index"    -- round-robin index

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
-- Logistic capability probing (core of auto-detection)
-- --------------------------------------------------------------------------------

--- Normalizes a get_logistic_point(nil or index) result into a flat array of points.
local function to_point_array(val)
  if not val then return {} end
  local points = {}
  local function push(p)
    if p then
      local ok_valid, v = pcall(function() return p.valid end)
      if not ok_valid or v ~= false then table.insert(points, p) end
    end
  end

  -- If it's a single LuaLogisticPoint
  local ok_obj, objname = pcall(function() return val.object_name end)
  if ok_obj and objname == "LuaLogisticPoint" then
    push(val)
    return points
  end

  -- If it's a table of points
  if type(val) == "table" then
    for _, p in pairs(val) do push(p) end
    return points
  end

  return points
end

--- Returns true if a logistic point is requester-like (requester or buffer) and enabled.
local function is_requester_like_enabled(point)
  if not point then return false end
  local ok_en, en = pcall(function() return point.enabled end)
  if ok_en and en == false then return false end
  local ok_mode, mode = pcall(function() return point.mode end)
  if not ok_mode then return false end
  return mode == defines.logistic_mode.requester or mode == defines.logistic_mode.buffer
end

--- Picks the "best" requester-like point: prefer requester; if none, fallback to buffer.
local function pick_best_requester_like_point(points)
  local buffer_fallback = nil
  for _, p in ipairs(points) do
    local ok_mode, mode = pcall(function() return p.mode end)
    if ok_mode then
      if mode == defines.logistic_mode.requester and is_requester_like_enabled(p) then
        return p
      elseif mode == defines.logistic_mode.buffer and is_requester_like_enabled(p) then
        buffer_fallback = buffer_fallback or p
      end
    end
  end
  return buffer_fallback
end

--- Probes an entity for requester-like capability and returns the chosen point or nil.
local function probe_requester_point(ent)
  if not (ent and ent.valid) then return nil end

  -- Best-effort: passing nil returns all logistic points for entities that have them.
  -- (On legacy cases, an explicit index may be required; we first try nil to cover future entities.)
  local ok_all, raw_all = pcall(function() return ent.get_logistic_point(nil) end)
  if ok_all and raw_all then
    local pts = to_point_array(raw_all)
    local chosen = pick_best_requester_like_point(pts)
    if chosen then return chosen end
  end

  -- Fallback pass: try known indices when available; if they don't exist, calls are safe via pcall.
  local indices = defines and defines.logistic_member_index or {}
  local try = {
    indices.character_requester,
    indices.spidertron_requester,
    indices.logistic_container,
    indices.space_platform_hub,
    indices.space_platform_hub_requester,
    indices.cargo_landing_pad,
    indices.cargo_landing_pad_requester
  }
  for _, idx in ipairs(try) do
    if idx ~= nil then
      local ok_one, raw = pcall(function() return ent.get_logistic_point(idx) end)
      if ok_one and raw then
        local pts = to_point_array(raw)
        local chosen = pick_best_requester_like_point(pts)
        if chosen then return chosen end
      end
    end
  end

  return nil
end

--- Returns true if the entity supports requester-like logistics (current or future).
local function entity_is_auto_supported(ent)
  if not (ent and ent.valid and ent.force and ent.force.name == "player") then return false end
  -- Must have a unit_number to be trackable.
  if not ent.unit_number then return false end
  -- Consider supported if we can probe a requester-like point (even if no active filters right now).
  return probe_requester_point(ent) ~= nil
end

-- --------------------------------------------------------------------------------
-- Entity tracking
-- --------------------------------------------------------------------------------

--- Adds an entity (by unit_number) to the tracked list (idempotent) if it is supported.
local function add_entity(ent)
  if not (ent and ent.valid and ent.unit_number) then return end
  if not entity_is_auto_supported(ent) then return end
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

--- Rebuilds the tracked entity list by scanning all surfaces for auto-supported entities.
local function refresh_entity_list()
  local new_list = {}
  for _, s in pairs(game.surfaces) do
    -- We fetch all entities for the player force, then probe; this runs only on enable or manual refresh.
    for _, ent in pairs(s.find_entities_filtered{force = "player"}) do
      if entity_is_auto_supported(ent) then
        table.insert(new_list, ent.unit_number)
      end
    end
  end
  storage[ENTITY_LIST_KEY] = new_list
end

-- --------------------------------------------------------------------------------
-- Sections & filters helpers
-- --------------------------------------------------------------------------------

--- Iterates over active sections of a logistic point and invokes cb(section).
--- Supports both 'sections' array and (sections_count + get_section(i)), then blind probing as fallback.
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

--- Fulfills all active requests for an entity's requester-like logistic point.
local function fulfill_all_active_requests(ent)
  local lp = probe_requester_point(ent)
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

--- Handler for when a logistic slot changes on an entity that exposes sections.
--- If the section is active and we have a filter at e.slot_index, fulfills just that filter.
function M.on_entity_logistic_slot_changed(e)
  if not is_enabled() then return end
  local ent = e and e.entity
  if not (ent and ent.valid and ent.force and ent.force.name == "player") then return end
  -- Only service entities we consider supported (cheap probe via requester point).
  if not entity_is_auto_supported(ent) then return end

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
    if ent and ent.valid then
      if entity_is_auto_supported(ent) then
        fulfill_all_active_requests(ent)
        i = i + 1
        if i > #list then i = 1 end
        break
      else
        -- Entity no longer exposes requester-like points; drop it.
        table.remove(list, i)
        if i > #list then i = 1 end
      end
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
    add_entity(ent)
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
