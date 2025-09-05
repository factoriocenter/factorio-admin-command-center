-- scripts/logistic-network/instant_trash.lua
-- Instant Trash (per-player + entity support)
--
-- Player behavior (unchanged):
--   * When enabled for a player, anything placed into their character trash
--     inventory is deleted immediately (hard-delete).
--   * If the player has logistic request filters with a "max" (max_count),
--     any excess above that max is moved to trash and then deleted.
--
-- NEW: Entity behavior (requester/buffer chests, spidertron, tank):
--   * When at least one player has Instant Trash enabled, supported entities
--     are scanned in a round-robin and their logistic filters are enforced.
--     Any item counts above each filter's "max"/"max_count" are removed from
--     the entity's inventories (deleted directly; no spill).
--
-- Notes:
--   * We avoid registering our own script.on_event here to keep compatibility
--     with a central dispatcher. This module works purely with functions
--     exposed to the dispatcher AND with a periodic background scan/refresh.
--   * Safe with Factorio 2.0.66 APIs: requester points may expose either
--     compiled filters (lp.filters) or sections/slots with .value/.max.
--
-- Performance:
--   * Round-robin both across players and across entities.
--   * Entity list is refreshed periodically (REFRESH_INTERVAL_TICKS).
--   * All heavy calls are guarded behind simple early-exit checks.

local M = {}

-- ------------------------------------------------------------------------------
-- Tunables
-- ------------------------------------------------------------------------------
local PER_TICK_PLAYERS       = 10     -- how many players to process per tick
local PER_TICK_ENTITIES      = 15     -- how many entities to process per tick
local REFRESH_INTERVAL_TICKS = 60*20  -- rebuild the entity list every 20s

-- ------------------------------------------------------------------------------
-- Storage keys
-- ------------------------------------------------------------------------------
local ENABLED_PLAYERS_KEY   = "facc_instant_trash_enabled_players" -- map[player_index]=true|false
local RR_PLAYER_IDX_KEY     = "facc_instant_trash_rr_player_index" -- round-robin index across players

local ENTITY_LIST_KEY       = "facc_instant_trash_entities"        -- array of unit_numbers
local RR_ENTITY_IDX_KEY     = "facc_instant_trash_rr_entity_index" -- round-robin index across entities
local LAST_REFRESH_TICK_KEY = "facc_instant_trash_last_refresh"    -- last tick we refreshed the entity list

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
  if t == "spider-vehicle" then return true end  -- spidertron
  if t == "car" and ent.name == "tank" then return true end
  if t == "character" then return true end
  return false
end

-- Keep a compact list of unit_numbers for supported entities
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
    -- Characters (optional; useful if you want to enforce max on non-local players)
    for _, ch in pairs(s.find_entities_filtered{force="player", type="character"}) do
      if is_supported_entity(ch) and ch.unit_number then
        new_list[#new_list+1] = ch.unit_number
      end
    end
  end
  storage[ENTITY_LIST_KEY] = new_list
  storage[RR_ENTITY_IDX_KEY] = 1
  storage[LAST_REFRESH_TICK_KEY] = game.tick
end

-- Optional hooks (if your central dispatcher forwards build/destroy events)
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
-- Utilities (players)
-- ------------------------------------------------------------------------------
local function get_trash_inv(player)
  if not (player and player.valid and player.character and player.character.valid) then return nil end
  return player.get_inventory(defines.inventory.character_trash)
end

local function purge_trash_now(player)
  local trash = get_trash_inv(player)
  if not trash or trash.is_empty() then return end
  -- Hard delete: clearing the trash inventory destroys items.
  trash.clear()
end

-- Normalize quality: string or table {name=...} -> string or nil
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

  -- Player: simpler API
  if owner.is_player() then
    if not (owner.character and owner.character.valid) then return nil end
    local ok, lp = pcall(function() return owner.get_requester_point() end)
    if not (ok and lp) then return nil end
    local ok_en, en = pcall(function() return lp.enabled end)
    if ok_en and en == false then return nil end
    return lp
  end

  -- Entity: we must choose a logistic_member_index
  local index
  if owner.type == "character" then
    index = defines.logistic_member_index.character_requester
  elseif owner.type == "logistic-container" then
    index = defines.logistic_member_index.logistic_container
  elseif owner.type == "spider-vehicle" then
    index = defines.logistic_member_index.spidertron_requester
  elseif owner.type == "car" then
    index = defines.logistic_member_index.logistic_container -- for tank
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
    return {
      name      = filter_like.name,
      quality   = as_quality_name(filter_like.quality),
      count     = filter_like.count,      -- requested
      max_count = filter_like.max_count,  -- cap
    }
  end
  -- Section slot shape (slot.value + slot.max / slot.count)
  local ok_v, value = pcall(function() return filter_like.value end)
  local name = ok_v and value and value.type == "item" and value.name or nil
  if not name then return nil end

  local ok_q, q = pcall(function() return value.quality end)
  local quality = ok_q and as_quality_name(q) or nil

  local ok_max, max_val = pcall(function() return filter_like.max end)
  local max_count = (ok_max and type(max_val) == "number") and max_val or nil

  local ok_cnt, cnt = pcall(function() return filter_like.count end)
  local count = (ok_cnt and type(cnt) == "number") and cnt or nil

  return { name = name, quality = quality, count = count, max_count = max_count }
end

-- ------------------------------------------------------------------------------
-- Trimming logic (player/entity)
-- ------------------------------------------------------------------------------
local function remove_excess(owner, item_name, quality, excess)
  if excess <= 0 then return end
  -- For entities, remove_item() deletes directly.
  -- For players, we prefer to route via trash (keeps behavior consistent),
  -- but removing directly is also fine. We'll keep the player path explicit.
  if owner.is_player and owner:is_player() then
    local removed = owner.remove_item({ name = item_name, count = excess, quality = quality })
    if removed > 0 then
      local trash = owner.get_inventory(defines.inventory.character_trash)
      if trash then trash.insert({ name = item_name, count = removed, quality = quality }) end
    end
  else
    owner.remove_item({ name = item_name, count = excess, quality = quality })
  end
end

local function total_count(owner, item_name, quality)
  local stack = {name = item_name}
  if quality then stack.quality = quality end
  local ok, n = pcall(function() return owner.get_item_count(stack) end)
  return (ok and tonumber(n)) or 0
end

-- Enforce "max_count" across all active filters for a given owner (player or entity)
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
        if excess > 0 then
          remove_excess(owner, pf.name, pf.quality, excess)
        end
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
        if excess > 0 then
          remove_excess(owner, pf.name, pf.quality, excess)
        end
      end
    end)
  end)
end

-- One unified pass for a player: trim max caps and purge trash.
local function handle_player(player)
  if not is_player_enabled(player) then return end
  trim_excess_from_filters(player)
  -- Make sure anything thrown into trash is destroyed immediately.
  local trash = get_trash_inv(player)
  if trash and not trash.is_empty() then trash.clear() end
end

-- One pass for an entity (only when any player has feature enabled)
local function handle_entity(ent)
  if not (ent and ent.valid and is_supported_entity(ent)) then return end
  if not any_player_enabled() then return end
  trim_excess_from_filters(ent)
end

-- Validate a player candidate for instant trash.
local function valid_candidate(player)
  return player
     and player.valid
     and player.connected
     and player.character
end

-- ------------------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------------------

-- Per-player toggle (invoked from GUI switch)
function M.toggle_player(player, enable)
  ensure_storage()
  if not (player and player.valid) then return end
  storage[ENABLED_PLAYERS_KEY][player.index] = (enable == true)
  if enable then
    player.print({"facc.instant-trash-enabled"})
  else
    player.print({"facc.instant-trash-disabled"})
  end
end

-- Inventory change events (player): purge now + respect filter max caps
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

-- Logistic slot changed (player or entity): re-trim and (for players) purge
function M.on_entity_logistic_slot_changed(e)
  -- Player path
  if e and e.player_index ~= nil then
    local player = game.get_player(e.player_index)
    if valid_candidate(player) then handle_player(player) end
  end
  -- Entity path
  local ent = e and e.entity
  if ent and ent.valid and is_supported_entity(ent) then
    handle_entity(ent)
  end
end

-- Central on_tick worker (players + entities)
function M.on_tick(_e)
  ensure_storage()

  -- Periodic entity list refresh (only if feature is globally "armed")
  if any_player_enabled() and (game.tick - storage[LAST_REFRESH_TICK_KEY] >= REFRESH_INTERVAL_TICKS) then
    refresh_entity_list()
  end

  -- Players round-robin
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

  -- Entities round-robin (only when at least one player enabled)
  if any_player_enabled() then
    local list = get_entity_list()
    if #list > 0 then
      local i = storage[RR_ENTITY_IDX_KEY]
      if i > #list then i = 1 end

      local processed = 0
      while processed < PER_TICK_ENTITIES and processed < #list do
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
