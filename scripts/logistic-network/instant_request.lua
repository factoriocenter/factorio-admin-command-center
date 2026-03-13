-- scripts/logistic-network/instant_request.lua
-- Instant Request

local M = {}
local flib_table = require("__flib__.table")
local flib_queue = require("__flib__.queue")

-- --------------------------------------------------------------------------------
-- Storage keys
-- --------------------------------------------------------------------------------

local ENABLED_KEY = "facc_instant_request_enabled"      -- boolean (global toggle)
local ENTITY_LIST_KEY = "facc_instant_request_entities" -- queue of unit_numbers
local ENTITY_SET_KEY = "facc_instant_request_entity_set"

-- --------------------------------------------------------------------------------
-- Storage helpers
-- --------------------------------------------------------------------------------

local function is_queue(value)
  return type(value) == "table" and type(value.first) == "number" and type(value.last) == "number"
end

local function array_to_queue(arr)
  local q = flib_queue.new()
  for i = 1, #arr do
    flib_queue.push_back(q, arr[i])
  end
  return q
end

local function ensure_entity_queue()
  local value = storage[ENTITY_LIST_KEY]
  if value == nil then
    value = flib_queue.new()
    storage[ENTITY_LIST_KEY] = value
    return value
  end

  if is_queue(value) then
    return value
  end

  if type(value) == "table" then
    local converted = array_to_queue(value)
    storage[ENTITY_LIST_KEY] = converted
    return converted
  end

  local fallback = flib_queue.new()
  storage[ENTITY_LIST_KEY] = fallback
  return fallback
end

local function ensure_entity_set(queue)
  local set = storage[ENTITY_SET_KEY]
  if set == nil then
    set = {}
    for _, un in flib_queue.iter(queue) do
      set[un] = true
    end
    storage[ENTITY_SET_KEY] = set
  end
  return set
end

--- Ensures storage keys exist with sane defaults.
local function ensure_storage()
  flib_table.get_or_insert(storage, ENABLED_KEY, false)
  local queue = ensure_entity_queue()
  ensure_entity_set(queue)
end

--- Returns whether the feature is globally enabled.
local function is_enabled()
  ensure_storage()
  return storage[ENABLED_KEY] == true
end

--- Returns the current queue and set for tracked entity unit_numbers.
local function get_entity_queue_and_set()
  ensure_storage()
  local queue = ensure_entity_queue()
  local set = ensure_entity_set(queue)
  return queue, set
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
  local queue, set = get_entity_queue_and_set()
  local un = ent.unit_number
  if set[un] then return end
  set[un] = true
  flib_queue.push_back(queue, un)
end

--- Removes an entity (by unit_number) from the tracked set.
--- Queue entries are cleaned lazily when popped on tick.
local function remove_entity(ent)
  local un = ent and ent.unit_number
  if not un then return end
  local _, set = get_entity_queue_and_set()
  set[un] = nil
end

--- Rebuilds the tracked entity queue by scanning all surfaces for auto-supported entities.
local function refresh_entity_queue()
  local queue = flib_queue.new()
  local set = {}
  flib_table.for_each(game.surfaces, function(s)
    -- We fetch all entities for the player force, then probe; this runs only on enable or manual refresh.
    flib_table.for_each(s.find_entities_filtered{force = "player"}, function(ent)
      if entity_is_auto_supported(ent) then
        local un = ent.unit_number
        if un and not set[un] then
          set[un] = true
          flib_queue.push_back(queue, un)
        end
      end
    end)
  end)
  storage[ENTITY_LIST_KEY] = queue
  storage[ENTITY_SET_KEY] = set
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
    refresh_entity_queue()
  else
    storage[ENTITY_LIST_KEY] = flib_queue.new()
    storage[ENTITY_SET_KEY] = {}
  end
  if player and player.valid then
    if enable then
      player.print({"facc.instant-request-enabled"})
    else
      player.print({"facc.instant-request-disabled"})
    end
  end
end

function M.on_entity_created(e)
  if not is_enabled() then return end
  local ent = e and (e.created_entity or e.entity) or nil
  add_entity(ent)
end

function M.on_entity_removed(e)
  if not is_enabled() then return end
  local ent = e and e.entity or nil
  remove_entity(ent)
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
  local queue, set = get_entity_queue_and_set()
  local attempts_total = flib_queue.length(queue)
  if attempts_total == 0 then return end

  for _ = 1, attempts_total do
    local un = flib_queue.pop_front(queue)
    if not un then
      break
    end

    if set[un] then
      local ent = game.get_entity_by_unit_number(un)
      if ent and ent.valid and entity_is_auto_supported(ent) then
        fulfill_all_active_requests(ent)
        flib_queue.push_back(queue, un)
        break
      end

      -- Entity no longer valid/supported: remove from tracked set.
      set[un] = nil
    end
  end
end

return M
