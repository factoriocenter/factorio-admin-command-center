-- scripts/logistic-network/instant_trash.lua
-- Instant Trash

local M = {}

-- ------------------------------------------------------------------------------
-- Tunables
-- ------------------------------------------------------------------------------
local PER_TICK_PLAYERS       = 10     -- how many players to process per tick
local PER_TICK_ENTITIES      = 15     -- how many entities to process per tick
local REFRESH_INTERVAL_TICKS = 60*20  -- entity list refresh every 20 seconds

-- ------------------------------------------------------------------------------
-- Storage keys
-- ------------------------------------------------------------------------------
local ENABLED_PLAYERS_KEY   = "facc_instant_trash_enabled_players" -- map[player_index]=true|false
local RR_PLAYER_IDX_KEY     = "facc_instant_trash_rr_player_index"
local ENTITY_LIST_KEY       = "facc_instant_trash_entities"        -- {unit_number,...}
local RR_ENTITY_IDX_KEY     = "facc_instant_trash_rr_entity_index"
local LAST_REFRESH_TICK_KEY = "facc_instant_trash_last_refresh"

-- ------------------------------------------------------------------------------
-- Storage helpers
-- ------------------------------------------------------------------------------
local function ensure_storage()
  storage[ENABLED_PLAYERS_KEY]   = storage[ENABLED_PLAYERS_KEY]   or {}
  storage[RR_PLAYER_IDX_KEY]     = storage[RR_PLAYER_IDX_KEY]     or 1
  storage[ENTITY_LIST_KEY]       = storage[ENTITY_LIST_KEY]       or {}
  storage[RR_ENTITY_IDX_KEY]     = storage[RR_ENTITY_IDX_KEY]     or 1
  storage[LAST_REFRESH_TICK_KEY] = storage[LAST_REFRESH_TICK_KEY] or 0
end

local function is_player_enabled(player)
  ensure_storage()
  return player and player.valid and storage[ENABLED_PLAYERS_KEY][player.index] == true
end

local function any_player_enabled()
  ensure_storage()
  for _, v in pairs(storage[ENABLED_PLAYERS_KEY]) do
    if v == true then return true end
  end
  return false
end

local function get_entity_list()
  ensure_storage()
  return storage[ENTITY_LIST_KEY]
end

-- ------------------------------------------------------------------------------
-- Support detection (entities)
-- ------------------------------------------------------------------------------
local function is_supported_entity(ent)
  if not (ent and ent.valid and ent.force and ent.force.name == "player") then return false end
  local t = ent.type
  if t == "logistic-container" then
    local mode = ent.prototype and ent.prototype.logistic_mode
    return mode == "requester" or mode == "buffer"
  end
  if t == "spider-vehicle" then return true end       -- spidertron
  if t == "car" and ent.name == "tank" then return true end
  if t == "rocket-silo" then return true end          -- NEW: rocket silo
  -- (characters are handled via player path; we don't include them in the entity list)
  return false
end

-- Refresh list with requester/buffer chests, spidertron, tank, rocket silo
local function refresh_entity_list()
  local new_list = {}
  for _, s in pairs(game.surfaces) do
    -- Chests (requester/buffer)
    for _, chest in pairs(s.find_entities_filtered{force="player", type="logistic-container"}) do
      if is_supported_entity(chest) and chest.unit_number then
        new_list[#new_list+1] = chest.unit_number
      end
    end
    -- Spidertron
    for _, sp in pairs(s.find_entities_filtered{force="player", type="spider-vehicle"}) do
      if is_supported_entity(sp) and sp.unit_number then
        new_list[#new_list+1] = sp.unit_number
      end
    end
    -- Tank
    for _, car in pairs(s.find_entities_filtered{force="player", type="car", name="tank"}) do
      if is_supported_entity(car) and car.unit_number then
        new_list[#new_list+1] = car.unit_number
      end
    end
    -- Rocket silo
    for _, silo in pairs(s.find_entities_filtered{force="player", type="rocket-silo"}) do
      if is_supported_entity(silo) and silo.unit_number then
        new_list[#new_list+1] = silo.unit_number
      end
    end
  end
  storage[ENTITY_LIST_KEY] = new_list
  storage[RR_ENTITY_IDX_KEY] = 1
  storage[LAST_REFRESH_TICK_KEY] = game.tick
end

-- Optional: allow external dispatcher to push adds/removes
function M.on_entity_created(e)
  local ent = (e and (e.created_entity or e.entity)) or nil
  if not (ent and ent.valid and ent.unit_number) then return end
  if not is_supported_entity(ent) then return end
  local list = get_entity_list()
  for _, un in ipairs(list) do if un == ent.unit_number then return end end
  list[#list+1] = ent.unit_number
end

function M.on_entity_removed(e)
  local ent = e and e.entity or nil
  if not (ent and ent.unit_number) then return end
  local list = get_entity_list()
  for i, un in ipairs(list) do
    if un == ent.unit_number then table.remove(list, i); break end
  end
end

-- ------------------------------------------------------------------------------
-- Trash inventories (player & entities)
-- ------------------------------------------------------------------------------
local function get_trash_inventory(owner)
  -- Player
  if owner.is_player and owner:is_player() then
    local ok, inv = pcall(function() return owner.get_inventory(defines.inventory.character_trash) end)
    if ok and inv then return inv end
    return nil
  end

  -- Entities (guard each enum; it may not exist in the running Factorio build)
  local inv_id = nil
  if owner.type == "logistic-container" then
    inv_id = defines.inventory and defines.inventory.logistic_container_trash
  elseif owner.type == "spider-vehicle" then
    inv_id = defines.inventory and (defines.inventory.spider_trash or defines.inventory.spider_vehicle_trash)
  elseif owner.type == "car" then
    -- If the build exposes car_trash, use it. Otherwise, no trash inventory for cars.
    inv_id = defines.inventory and defines.inventory.car_trash
  elseif owner.type == "rocket-silo" then
    -- NEW: rocket silo trash inventory (if present in this Factorio build)
    inv_id = defines.inventory and (defines.inventory.rocket_silo_trash or defines.inventory.rocket_silo_trash_inventory)
  elseif owner.type == "character" then
    inv_id = defines.inventory and defines.inventory.character_trash
  end

  if not inv_id then return nil end
  local ok, inv = pcall(function() return owner.get_inventory(inv_id) end)
  if ok and inv then return inv end
  return nil
end

local function purge_owner_trash(owner)
  local inv = get_trash_inventory(owner)
  if inv and not inv.is_empty() then inv.clear() end
end

-- ------------------------------------------------------------------------------
-- Quality helpers
-- ------------------------------------------------------------------------------
local function as_quality_name(q)
  if not q then return nil end
  if type(q) == "string" then return q end
  if type(q) == "table" and q.name then return q.name end
  return nil
end

-- ------------------------------------------------------------------------------
-- Requester point (player or entity)
-- ------------------------------------------------------------------------------
local function get_requester_point_generic(owner)
  if not (owner and owner.valid) then return nil end

  -- Player
  if owner.is_player and owner:is_player() then
    if not (owner.character and owner.character.valid) then return nil end
    local ok, lp = pcall(function() return owner.get_requester_point() end)
    if not (ok and lp) then return nil end
    local ok_en, en = pcall(function() return lp.enabled end)
    if ok_en and en == false then return nil end
    return lp
  end

  -- Entity
  local index
  if owner.type == "character" then
    index = defines.logistic_member_index.character_requester
  elseif owner.type == "logistic-container" then
    index = defines.logistic_member_index.logistic_container
  elseif owner.type == "spider-vehicle" then
    index = defines.logistic_member_index.spidertron_requester
  elseif owner.type == "car" then
    -- Treat tank as a logistic container member for requester point purposes.
    index = defines.logistic_member_index.logistic_container
  elseif owner.type == "rocket-silo" then
    -- Rocket silo normally doesn't expose a requester point; skip trimming filters.
    return nil
  else
    return nil
  end

  local ok, lp = pcall(function() return owner.get_logistic_point(index) end)
  if not (ok and lp) then return nil end
  local ok_en, en = pcall(function() return lp.enabled end)
  if ok_en and en == false then return nil end
  return lp
end

-- Iterate active sections
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
end

-- Iterate filters (slots) in a section
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

-- Extract filter info from multiple representations
local function parse_filter(filter_like)
  -- CompiledLogisticFilter shape
  if filter_like.name then
    local max_count = filter_like.max_count or filter_like.count -- fallback
    return {
      name      = filter_like.name,
      quality   = as_quality_name(filter_like.quality),
      count     = filter_like.count,
      max_count = max_count,
    }
  end
  -- Section slot shape
  local ok_v, value = pcall(function() return filter_like.value end)
  local name = ok_v and value and value.type == "item" and value.name or nil
  if not name then return nil end

  local ok_q, q = pcall(function() return value.quality end)
  local quality = ok_q and as_quality_name(q) or nil

  local ok_max, max_val = pcall(function() return filter_like.max end)
  local max_count = (ok_max and type(max_val) == "number") and max_val or nil

  local ok_cnt, cnt = pcall(function() return filter_like.count end)
  local count = (ok_cnt and type(cnt) == "number") and cnt or nil

  if max_count == nil and count ~= nil then
    max_count = count
  end

  return { name = name, quality = quality, count = count, max_count = max_count }
end

-- ------------------------------------------------------------------------------
-- Trimming logic (player/entity)
-- ------------------------------------------------------------------------------
local function total_count(owner, item_name, quality)
  local stack = {name = item_name}
  if quality then stack.quality = quality end
  local ok, n = pcall(function() return owner.get_item_count(stack) end)
  return (ok and tonumber(n)) or 0
end

local function remove_excess(owner, item_name, quality, excess)
  if excess <= 0 then return end
  -- Player path: route via trash to keep behavior consistent, then purge.
  if owner.is_player and owner:is_player() then
    local removed = owner.remove_item({ name = item_name, count = excess, quality = quality })
    if removed > 0 then
      local trash = get_trash_inventory(owner)
      if trash then trash.insert({ name = item_name, count = removed, quality = quality }) end
    end
  else
    -- Entities: removing deletes directly.
    owner.remove_item({ name = item_name, count = excess, quality = quality })
  end
end

local function trim_excess_from_filters(owner)
  local lp = get_requester_point_generic(owner)
  if not lp then return end

  -- Try compiled filters first
  local ok_f, list = pcall(function() return lp.filters end)
  if ok_f and type(list) == "table" then
    for _, f in ipairs(list) do
      local pf = parse_filter(f)
      if pf and pf.max_count then
        local have = total_count(owner, pf.name, pf.quality)
        local excess = have - pf.max_count
        if excess > 0 then remove_excess(owner, pf.name, pf.quality, excess) end
      end
    end
    return
  end

  -- Fallback: iterate sections/slots
  iter_active_sections(lp, function(section)
    iter_filters(section, function(filter_like)
      local pf = parse_filter(filter_like)
      if pf and pf.max_count then
        local have = total_count(owner, pf.name, pf.quality)
        local excess = have - pf.max_count
        if excess > 0 then remove_excess(owner, pf.name, pf.quality, excess) end
      end
    end)
  end)
end

-- Player pass: trim + purge trash now
local function handle_player(player)
  if not is_player_enabled(player) then return end
  trim_excess_from_filters(player)
  purge_owner_trash(player)
end

-- Entity pass: trim + purge entity trash now
local function handle_entity(ent)
  if not (ent and ent.valid and is_supported_entity(ent)) then return end
  if not any_player_enabled() then return end
  trim_excess_from_filters(ent)
  purge_owner_trash(ent)  -- clears logistic_container_trash / spider_trash / car_trash / rocket_silo_trash (when available)
end

-- Validate a player candidate
local function valid_candidate(player)
  return player and player.valid and player.connected and player.character
end

-- ------------------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------------------
function M.toggle_player(player, enable)
  ensure_storage()
  if not (player and player.valid) then return end
  storage[ENABLED_PLAYERS_KEY][player.index] = (enable == true)
  if enable then
    refresh_entity_list()
    player.print({"facc.instant-trash-enabled"})
  else
    player.print({"facc.instant-trash-disabled"})
  end
end

-- Player inventory changes
function M.on_player_main_inventory_changed(e)
  local player = e and e.player_index and game.get_player(e.player_index) or nil
  if valid_candidate(player) then handle_player(player) end
end
function M.on_player_ammo_inventory_changed(e)
  local player = e and e.player_index and game.get_player(e.player_index) or nil
  if valid_candidate(player) then handle_player(player) end
end
function M.on_player_cursor_stack_changed(e)
  local player = e and e.player_index and game.get_player(e.player_index) or nil
  if valid_candidate(player) then handle_player(player) end
end

-- Logistic slot changed (player or entity)
function M.on_entity_logistic_slot_changed(e)
  if e and e.player_index ~= nil then
    local player = game.get_player(e.player_index)
    if valid_candidate(player) then handle_player(player) end
  end
  local ent = e and e.entity
  if ent and ent.valid and is_supported_entity(ent) then
    handle_entity(ent)
  end
end

-- Central on_tick worker (players + entities)
function M.on_tick(_e)
  ensure_storage()

  -- Periodic entity list refresh
  if any_player_enabled() and (game.tick - storage[LAST_REFRESH_TICK_KEY] >= REFRESH_INTERVAL_TICKS) then
    refresh_entity_list()
  end

  -- Players RR
  local players = game.connected_players
  if #players > 0 then
    local i = storage[RR_PLAYER_IDX_KEY]
    if i > #players then i = 1 end
    local processed = 0
    while processed < PER_TICK_PLAYERS and processed < #players do
      local p = players[i]
      if valid_candidate(p) and is_player_enabled(p) then
        handle_player(p)
      end
      i = i + 1
      if i > #players then i = 1 end
      processed = processed + 1
    end
    storage[RR_PLAYER_IDX_KEY] = i
  end

  -- Entities RR (only if any player enabled)
  if any_player_enabled() then
    local list = get_entity_list()
    if #list > 0 then
      local i = storage[RR_ENTITY_IDX_KEY]
      if i > #list then i = 1 end
      local processed = 0
      local max_loop = #list
      while processed < PER_TICK_ENTITIES and processed < max_loop do
        local un = list[i]
        local ent = game.get_entity_by_unit_number(un)
        if ent and ent.valid and is_supported_entity(ent) then
          handle_entity(ent)
          i = i + 1
          if i > #list then i = 1 end
        else
          table.remove(list, i)
          if i > #list then i = 1 end
        end
        processed = processed + 1
      end
      storage[RR_ENTITY_IDX_KEY] = i
    end
  end
end

return M
