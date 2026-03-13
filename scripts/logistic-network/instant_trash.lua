-- scripts/logistic-network/instant_trash.lua
-- Instant Trash
local M = {}
local flib_table = require("__flib__.table")
local flib_queue = require("__flib__.queue")
-- ------------------------------------------------------------------------------
-- Tunables
-- ------------------------------------------------------------------------------
local PER_TICK_PLAYERS = 10 -- how many players to process per tick
local PER_TICK_ENTITIES = 15 -- how many entities to process per tick
local REFRESH_INTERVAL_TICKS = 60*20 -- entity list refresh every 20 seconds
-- ------------------------------------------------------------------------------
-- Storage keys
-- ------------------------------------------------------------------------------
local ENABLED_PLAYERS_KEY = "facc_instant_trash_enabled_players" -- map[player_index]=true|false
local ENABLED_COUNT_KEY = "facc_instant_trash_enabled_count"
local RR_PLAYER_IDX_KEY = "facc_instant_trash_rr_player_index"
local ENTITY_LIST_KEY = "facc_instant_trash_entities" -- queue of unit_numbers
local ENTITY_SET_KEY = "facc_instant_trash_entity_set"
local LAST_REFRESH_TICK_KEY = "facc_instant_trash_last_refresh"
local INV_IDS_KEY = "facc_instant_trash_inventory_ids" -- cached resolved inventory ids
-- ------------------------------------------------------------------------------
-- Storage helpers
-- ------------------------------------------------------------------------------
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

local function ensure_enabled_count()
  local enabled_players = flib_table.get_or_insert(storage, ENABLED_PLAYERS_KEY, {})
  local count = storage[ENABLED_COUNT_KEY]
  if type(count) == "number" then
    if count < 0 then
      count = 0
      storage[ENABLED_COUNT_KEY] = count
    end
    return count
  end

  count = 0
  for _, v in pairs(enabled_players) do
    if v == true then
      count = count + 1
    end
  end
  storage[ENABLED_COUNT_KEY] = count
  return count
end

local function ensure_storage()
  flib_table.get_or_insert(storage, ENABLED_PLAYERS_KEY, {})
  ensure_enabled_count()
  flib_table.get_or_insert(storage, RR_PLAYER_IDX_KEY, 1)
  local queue = ensure_entity_queue()
  ensure_entity_set(queue)
  flib_table.get_or_insert(storage, LAST_REFRESH_TICK_KEY, 0)
  flib_table.get_or_insert(storage, INV_IDS_KEY, { probed = false })
end
local function is_player_enabled(player)
  ensure_storage()
  return player and player.valid and storage[ENABLED_PLAYERS_KEY][player.index] == true
end
local function any_player_enabled()
  ensure_storage()
  return ensure_enabled_count() > 0
end
local function get_entity_list()
  ensure_storage()
  local queue = ensure_entity_queue()
  local set = ensure_entity_set(queue)
  return queue, set
end
-- ------------------------------------------------------------------------------
-- Inventory id probing (robust across builds)
-- ------------------------------------------------------------------------------
local function ensure_inventory_ids()
  ensure_storage()
  local ids = storage[INV_IDS_KEY]
  if ids.probed then return ids end
  -- Resolve inventory IDs in a best-effort way. Some builds rename or omit these.
  if defines.inventory then
    ids.character_trash = defines.inventory.character_trash
    ids.logistic_container_trash = defines.inventory.logistic_container_trash
    ids.spider_trash = defines.inventory.spider_trash or defines.inventory.spider_vehicle_trash
    ids.car_trash = defines.inventory.car_trash
    -- Rocket silo trash: try the common keys (both guarded)
    ids.rocket_silo_trash = defines.inventory.rocket_silo_trash
                                  or defines.inventory.rocket_silo_trash_inventory
    ids.cargo_landing_pad_trash = defines.inventory.cargo_landing_pad_trash
    ids.character_main = defines.inventory.character_main
    ids.chest = defines.inventory.chest
    ids.spider_trunk = defines.inventory.spider_trunk
    ids.car_trunk = defines.inventory.car_trunk
    ids.rocket_silo_rocket = defines.inventory.rocket_silo_rocket
    ids.cargo_landing_pad_main = defines.inventory.cargo_landing_pad_main
  end
  ids.probed = true
  return ids
end
-- ------------------------------------------------------------------------------
-- Support detection (entities)
-- ------------------------------------------------------------------------------
local function is_supported_entity(ent)
  if not (ent and ent.valid) then return false end
  local ok_force, force = pcall(function() return ent.force end)
  if not (ok_force and force and force.valid and force.name == "player") then return false end
  local t = ent.type
  if t == "logistic-container" then
    local mode = ent.prototype and ent.prototype.logistic_mode
    return mode == "requester" or mode == "buffer"
  end
  if t == "spider-vehicle" then return true end -- spidertron
  if t == "car" and ent.name == "tank" then return true end
  if t == "rocket-silo" then return true end -- rocket silo
  if t == "cargo-landing-pad" then return true end -- cargo landing pad
  -- (characters are handled via player path; we don't include them in the entity list)
  return false
end
-- Refresh list with requester/buffer chests, spidertron, tank, rocket silo, cargo landing pad
local function refresh_entity_list()
  local queue = flib_queue.new()
  local set = {}

  local function push_un(un)
    if not un or set[un] then
      return
    end
    set[un] = true
    flib_queue.push_back(queue, un)
  end

  flib_table.for_each(game.surfaces, function(s)
    -- Chests (requester/buffer)
    flib_table.for_each(s.find_entities_filtered{force="player", type="logistic-container"}, function(chest)
      if is_supported_entity(chest) and chest.unit_number then
        push_un(chest.unit_number)
      end
    end)
    -- Spidertron
    flib_table.for_each(s.find_entities_filtered{force="player", type="spider-vehicle"}, function(sp)
      if is_supported_entity(sp) and sp.unit_number then
        push_un(sp.unit_number)
      end
    end)
    -- Tank
    flib_table.for_each(s.find_entities_filtered{force="player", type="car", name="tank"}, function(car)
      if is_supported_entity(car) and car.unit_number then
        push_un(car.unit_number)
      end
    end)
    -- Rocket silo
    flib_table.for_each(s.find_entities_filtered{force="player", type="rocket-silo"}, function(silo)
      if is_supported_entity(silo) and silo.unit_number then
        push_un(silo.unit_number)
      end
    end)
    -- Cargo landing pad
    flib_table.for_each(s.find_entities_filtered{force="player", type="cargo-landing-pad"}, function(pad)
      if is_supported_entity(pad) and pad.unit_number then
        push_un(pad.unit_number)
      end
    end)
  end)
  storage[ENTITY_LIST_KEY] = queue
  storage[ENTITY_SET_KEY] = set
  storage[LAST_REFRESH_TICK_KEY] = game.tick
end
-- Optional: allow external dispatcher to push adds/removes
function M.on_entity_created(e)
  local ent = (e and (e.created_entity or e.entity)) or nil
  if not (ent and ent.valid and ent.unit_number) then return end
  if not is_supported_entity(ent) then return end
  local queue, set = get_entity_list()
  local un = ent.unit_number
  if set[un] then return end
  set[un] = true
  flib_queue.push_back(queue, un)
end
function M.on_entity_removed(e)
  local ent = e and e.entity or nil
  if not (ent and ent.unit_number) then return end
  local _, set = get_entity_list()
  set[ent.unit_number] = nil
end
-- ------------------------------------------------------------------------------
-- Trash inventories (player & entities)
-- ------------------------------------------------------------------------------
local function get_trash_inventory(owner)
  local ids = ensure_inventory_ids()
  -- Player
  if owner.is_player and owner:is_player() then
    local ok, inv = pcall(function() return owner.get_inventory(ids.character_trash) end)
    if ok and inv then return inv end
    return nil
  end
  -- Entities (guard each id; id may be nil on some builds)
  local inv_id = nil
  if owner.type == "logistic-container" then
    inv_id = ids.logistic_container_trash
  elseif owner.type == "spider-vehicle" then
    inv_id = ids.spider_trash
  elseif owner.type == "car" then
    inv_id = ids.car_trash
  elseif owner.type == "rocket-silo" then
    inv_id = ids.rocket_silo_trash
  elseif owner.type == "cargo-landing-pad" then
    inv_id = ids.cargo_landing_pad_trash
  elseif owner.type == "character" then
    inv_id = ids.character_trash
  end
  if not inv_id then return nil end
  local ok, inv = pcall(function() return owner.get_inventory(inv_id) end)
  if ok and inv then return inv end
  return nil
end
local function get_main_inventory(owner)
  local ids = ensure_inventory_ids()
  -- Player
  if owner.is_player and owner:is_player() then
    local ok, inv = pcall(function() return owner.get_inventory(ids.character_main) end)
    if ok and inv then return inv end
    return nil
  end
  -- Entities (guard each id; id may be nil on some builds)
  local inv_id = nil
  if owner.type == "logistic-container" then
    inv_id = ids.chest
  elseif owner.type == "spider-vehicle" then
    inv_id = ids.spider_trunk
  elseif owner.type == "car" then
    inv_id = ids.car_trunk
  elseif owner.type == "rocket-silo" then
    inv_id = ids.rocket_silo_rocket
  elseif owner.type == "cargo-landing-pad" then
    inv_id = ids.cargo_landing_pad_main
  elseif owner.type == "character" then
    inv_id = ids.character_main
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
    index = defines.logistic_member_index.rocket_silo_requester
  elseif owner.type == "cargo-landing-pad" then
    index = defines.logistic_member_index.space_platform_hub_requester
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
      name = filter_like.name,
      quality = as_quality_name(filter_like.quality),
      count = filter_like.count,
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
  local main_inv = get_main_inventory(owner)
  if not main_inv then return 0 end
  local ok, n = pcall(function() return main_inv.get_item_count(stack) end)
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
  purge_owner_trash(ent)
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
  local enabled_players = storage[ENABLED_PLAYERS_KEY]
  local was_enabled = enabled_players[player.index] == true
  local now_enabled = (enable == true)
  enabled_players[player.index] = now_enabled

  if was_enabled ~= now_enabled then
    local count = ensure_enabled_count()
    if now_enabled then
      count = count + 1
    else
      count = count - 1
    end
    if count < 0 then
      count = 0
    end
    storage[ENABLED_COUNT_KEY] = count
  end

  if enable then
    refresh_entity_list()
    player.print({"facc.instant-trash-enabled"})
  else
    player.print({"facc.instant-trash-disabled"})
  end
end

function M.has_enabled_players()
  return any_player_enabled()
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
  local has_enabled_players = any_player_enabled()
  -- Periodic entity list refresh
  if has_enabled_players and (game.tick - storage[LAST_REFRESH_TICK_KEY] >= REFRESH_INTERVAL_TICKS) then
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
  if has_enabled_players then
    local queue, set = get_entity_list()
    local queue_len = flib_queue.length(queue)
    if queue_len > 0 then
      local processed = 0
      local max_loop = queue_len
      while processed < PER_TICK_ENTITIES and processed < max_loop do
        local un = flib_queue.pop_front(queue)
        if not un then
          break
        end

        if set[un] then
          local ent = game.get_entity_by_unit_number(un)
          if ent and ent.valid and is_supported_entity(ent) then
            handle_entity(ent)
            flib_queue.push_back(queue, un)
          else
            set[un] = nil
          end
        end

        processed = processed + 1
      end
    end
  end
  -- Additional: purge trash for currently opened entities (instant while GUI open)
  if has_enabled_players then
    flib_table.for_each(game.connected_players, function(player)
      if is_player_enabled(player) then
        local opened = player.opened
        if opened and opened.valid and is_supported_entity(opened) then
          purge_owner_trash(opened)
        end
      end
    end)
  end
end
return M
