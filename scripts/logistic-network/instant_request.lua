-- scripts/logistic-network/instant_request.lua
-- Instant Request: Fulfills logistic requests immediately for supported entities.
-- Supports characters, requester/buffer chests, spidertrons, and tanks (if applicable).
-- Global toggle: when enabled, monitors slot changes and fulfills requests.
local M = {}

-- --------------------------------------------------------------------------------
-- Storage keys
-- --------------------------------------------------------------------------------
local ENABLED_KEY = "facc_instant_request_enabled" -- boolean (global toggle)
local ENTITY_LIST_KEY = "facc_instant_request_entities" -- array of unit_numbers
local RR_INDEX_KEY = "facc_instant_request_rr_index" -- round-robin index

-- --------------------------------------------------------------------------------
-- Storage helpers
-- --------------------------------------------------------------------------------
local function ensure_storage()
  storage[ENABLED_KEY] = storage[ENABLED_KEY] or false
  storage[ENTITY_LIST_KEY] = storage[ENTITY_LIST_KEY] or {}
  storage[RR_INDEX_KEY] = storage[RR_INDEX_KEY] or 1
end

local function is_enabled()
  ensure_storage()
  return storage[ENABLED_KEY] == true
end

local function get_entity_list()
  ensure_storage()
  return storage[ENTITY_LIST_KEY]
end

-- --------------------------------------------------------------------------------
-- Entity management
-- --------------------------------------------------------------------------------
local function is_supported_entity(ent)
  if not (ent and ent.valid and ent.force.name == "player") then return false end
  local t = ent.type
  if t == "character" then return true end
  if t == "spider-vehicle" then return true end
  if t == "car" and ent.name == "tank" then return true end
  if t == "container" then
    local mode = ent.prototype.logistic_mode
    return mode == "requester" or mode == "buffer"
  end
  return false
end

local function add_entity(ent)
  if not (ent and ent.valid and ent.unit_number) then return end
  local list = get_entity_list()
  for _, un in ipairs(list) do
    if un == ent.unit_number then return end
  end
  table.insert(list, ent.unit_number)
end

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

local function refresh_entity_list()
  local list = get_entity_list()
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
local function get_requester_point(ent)
  local index
  if ent.type == "character" then
    index = defines.logistic_member_index.character_requester
  elseif ent.type == "container" then
    index = defines.logistic_member_index.logistic_container
  elseif ent.type == "spider-vehicle" then
    index = defines.logistic_member_index.spidertron_requester
  elseif ent.type == "car" then
    index = defines.logistic_member_index.logistic_container -- assuming for tank
  else
    return nil
  end
  local ok, lp = pcall(function() return ent.get_logistic_point(index) end)
  if not (ok and lp) then return nil end
  local ok_en, en = pcall(function() return lp.enabled end)
  if ok_en and en == false then return nil end
  return lp
end

local function iter_active_sections(lp, cb)
  if not lp then return end
  local ok_prop, sections = pcall(function() return lp.sections end)
  if ok_prop and type(sections) == "table" then
    for _, sec in ipairs(sections) do
      local ok_act, active = pcall(function() return sec.active end)
      if ok_act and active then cb(sec) end
    end
    return
  end
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
  local i = 1
  while i <= 50 do
    local ok_gs, sec = pcall(function() return lp.get_section(i) end)
    if not ok_gs or not sec then break end
    local ok_act, active = pcall(function() return sec.active end)
    if ok_act and active then cb(sec) end
    i = i + 1
  end
end

local function iter_filters(section, cb)
  local ok, filters = pcall(function() return section.filters end)
  if ok and type(filters) == "table" then
    for _, f in ipairs(filters) do cb(f) end
    return
  end
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

local function total_count(ent, item_name, quality)
  local stack = {name = item_name}
  if quality then stack.quality = quality end
  local ok, n = pcall(function() return ent.get_item_count(stack) end)
  return (ok and tonumber(n)) or 0
end

local function try_insert(ent, name, want, quality)
  if want <= 0 then return 0 end
  local stack = { name = name, count = want }
  if quality then stack.quality = quality end
  local ok, ins = pcall(function() return ent.insert(stack) end)
  return (ok and tonumber(ins)) or 0
end

local function fulfill_filter(ent, filter)
  local req = extract_item_request(filter)
  if not req then return end
  local have = total_count(ent, req.name, req.quality)
  local need = (req.min or 0) - have
  if need > 0 then
    try_insert(ent, req.name, need, req.quality)
  end
end

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

function M.on_entity_logistic_slot_changed(e)
  if not is_enabled() then return end
  local ent = e and e.entity
  if not (ent and ent.valid and ent.force.name == "player" and is_supported_entity(ent)) then return end
  local sec = e.section
  local ok_act, active = pcall(function() return sec.active end)
  if not (ok_act and active) then return end
  local ok_slot, filter = pcall(function() return sec.get_slot(e.slot_index) end)
  if ok_slot and filter then
    fulfill_filter(ent, filter)
  end
end

function M.on_player_main_inventory_changed(e)
  if not is_enabled() then return end
  local player = e and e.player_index and game.get_player(e.player_index) or nil
  if not (player and player.valid and player.character and player.character.valid) then return end
  fulfill_all_active_requests(player.character)
end

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

-- Event handlers for adding/removing entities
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built}, function(e)
  local ent = e.created_entity or e.entity
  if is_enabled() and is_supported_entity(ent) then
    add_entity(ent)
  end
end)

script.on_event({defines.events.on_entity_died, defines.events.on_robot_mined_entity, defines.events.on_player_mined_entity, defines.events.script_raised_destroy}, function(e)
  local ent = e.entity
  if is_enabled() then
    remove_entity(ent)
  end
end)

return M