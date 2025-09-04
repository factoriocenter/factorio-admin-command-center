-- scripts/logistic-network/instant_request.lua

local M = {}

-- --------------------------------------------------------------------------------
-- Storage keys
-- --------------------------------------------------------------------------------
local ENABLE_MAP_KEY       = "facc_instant_request_players"           -- [player_index] = boolean
local RR_NEXT_PLAYER_KEY   = "facc_instant_request_next_player_index" -- round-robin pointer

-- --------------------------------------------------------------------------------
-- Storage helpers
-- --------------------------------------------------------------------------------
local function ensure_storage()
  storage[ENABLE_MAP_KEY]     = storage[ENABLE_MAP_KEY]     or {}
  storage[RR_NEXT_PLAYER_KEY] = storage[RR_NEXT_PLAYER_KEY] or 1
  return storage[ENABLE_MAP_KEY]
end

local function is_enabled_for_player(player)
  local map = ensure_storage()
  return player
    and player.valid
    and player.connected
    and player.character
    and player.character.valid
    and map[player.index] == true
end

-- --------------------------------------------------------------------------------
-- Low-level helpers (safe accessors)
-- --------------------------------------------------------------------------------
local function get_requester_point(player)
  local ok, lp = pcall(function()
    return player.get_requester_point and player.get_requester_point()
  end)
  if not ok or not lp then return nil end

  local ok_en, en = pcall(function() return lp.enabled end)
  if ok_en and en == false then return nil end
  return lp
end

--- Iterate personal request sections of a player (active ones only), calling cb(section).
local function iter_active_sections(player, cb)
  local lp = get_requester_point(player)
  if not lp then return end

  -- Try property .sections first
  local ok_prop, sections = pcall(function() return lp.sections end)
  if ok_prop and type(sections) == "table" then
    for _, sec in ipairs(sections) do
      local ok_act, active = pcall(function() return sec.active end)
      if ok_act and active then cb(sec) end
    end
    return
  end

  -- Fallback: use sections_count/get_section(i)
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

  -- Ultimate fallback: probe sequentially up to a safe bound
  local i = 1
  while i <= 50 do
    local ok_gs, sec = pcall(function() return lp.get_section(i) end)
    if not ok_gs or not sec then break end
    local ok_act, active = pcall(function() return sec.active end)
    if ok_act and active then cb(sec) end
    i = i + 1
  end
end

--- Iterate filters in a section, calling cb(filter).
local function iter_filters(section, cb)
  local ok, filters = pcall(function() return section.filters end)
  if ok and type(filters) == "table" then
    for _, f in ipairs(filters) do cb(f) end
    return
  end

  -- Fallback: probe get_slot(i)
  local i = 1
  while i <= 50 do
    local ok_s, slot = pcall(function() return section.get_slot(i) end)
    if not ok_s or not slot then break end
    cb(slot)
    i = i + 1
  end
end

-- --------------------------------------------------------------------------------
-- Refilling logic (preserves item quality when provided by the filter)
-- --------------------------------------------------------------------------------
local function extract_item_request(filter)
  -- Expected filter shape (2.0 personal logistics):
  --   filter.value = {type="item", name=..., quality?}, filter.min = desired
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
    -- Fallbacks (other mods / older shapes)
    local ok_cnt, cnt = pcall(function() return filter.count end)
    req_min = (ok_cnt and tonumber(cnt)) or 0
  end

  local quality
  local ok_q, q = pcall(function() return value.quality end)
  if ok_q and q then quality = q end

  return { name = name, min = req_min or 0, quality = quality }
end

local function player_total_count(player, item_name, quality)
  -- Count items. If quality is specified (Quality DLC), try to count exact quality;
  -- if not supported, fallback to total count.
  if not player or not item_name then return 0 end

  if quality ~= nil then
    local ok, n = pcall(function() return player.get_item_count({name = item_name, quality = quality}) end)
    if ok and type(n) == "number" then return n end
  end

  local ok2, n2 = pcall(function() return player.get_item_count(item_name) end)
  return (ok2 and tonumber(n2)) or 0
end

local function try_insert_player(player, name, want, quality)
  if want <= 0 then return 0 end
  local stack = { name = name, count = want }
  if quality ~= nil then stack.quality = quality end
  local ok, ins = pcall(function() return player.insert(stack) end)
  return (ok and tonumber(ins)) or 0
end

local function fulfill_filter_for_player(player, filter)
  local req = extract_item_request(filter)
  if not req then return end

  local have = player_total_count(player, req.name, req.quality)
  local need = (req.min or 0) - have
  if need > 0 then
    try_insert_player(player, req.name, need, req.quality)
  end
end

local function fulfill_all_active_requests(player)
  iter_active_sections(player, function(section)
    iter_filters(section, function(filter)
      fulfill_filter_for_player(player, filter)
    end)
  end)
end

-- --------------------------------------------------------------------------------
-- Public API: toggle & event handlers
-- --------------------------------------------------------------------------------

--- Toggle per-player Instant Request.
function M.toggle_player(player, enable, source_player)
  local actor = source_player or player
  if not (_G.is_allowed and _G.is_allowed(actor)) then
    if actor and actor.valid then actor.print({"facc.not-allowed"}) end
    return
  end

  local map = ensure_storage()
  map[player.index] = (enable == true)

  -- Immediate top-up on enable (visible effect)
  if enable and player and player.valid then
    fulfill_all_active_requests(player)
  end

  -- Feedback messages (locale-based)
  if source_player and source_player.valid and source_player.index ~= player.index then
    -- Target sees "enabled/disabled by admin <name>"
    if enable then
      if player and player.valid then
        player.print({"facc.instant-request-enabled-by-admin", source_player.name})
      end
      if source_player and source_player.valid then
        source_player.print({"facc.instant-request-you-enabled-for", player.name})
      end
    else
      if player and player.valid then
        player.print({"facc.instant-request-disabled-by-admin", source_player.name})
      end
      if source_player and source_player.valid then
        source_player.print({"facc.instant-request-you-disabled-for", player.name})
      end
    end
  else
    -- Self-toggle
    if player and player.valid then
      if enable then
        player.print({"facc.instant-request-enabled"})
      else
        player.print({"facc.instant-request-disabled"})
      end
    end
  end
end

--- Called when a personal logistics slot changes.
function M.on_entity_logistic_slot_changed(e)
  -- e.entity is expected to be a character when the change is on a player.
  local ent = e and e.entity
  if not (ent and ent.valid and ent.type == "character") then return end

  -- Resolve the controlling player
  local player = nil
  -- Try direct
  local ok_p, p = pcall(function() return ent.player end)
  if ok_p and p then player = p end
  -- Fallback by scan
  if not player then
    for _, pl in pairs(game.players) do
      if pl and pl.valid and pl.character == ent then player = pl; break end
    end
  end
  if not is_enabled_for_player(player) then return end

  -- If the section is active, fulfill that slot only; else bail.
  local sec = e.section
  local ok_active, active = pcall(function() return sec and sec.active end)
  if not (ok_active and active) then return end

  local ok_slot, filter = pcall(function() return sec.get_slot and sec.get_slot(e.slot_index) end)
  if ok_slot and filter then
    fulfill_filter_for_player(player, filter)
  end
end

--- Called when the player's main inventory changes.
function M.on_player_main_inventory_changed(e)
  local player = e and e.player_index and game.get_player(e.player_index) or nil
  if not is_enabled_for_player(player) then return end
  fulfill_all_active_requests(player)
end

--- Lightweight round-robin sweep: processes at most 1 player per tick.
function M.on_tick(_e)
  local map = ensure_storage()
  if not next(map) then return end

  local players = game.players
  if not players or #players == 0 then return end

  local i = storage[RR_NEXT_PLAYER_KEY]
  if i > #players then i = 1 end

  -- Walk until we find someone enabled (max N attempts to avoid infinite loops).
  local attempts = 0
  while attempts < #players do
    local p = players[i]
    if is_enabled_for_player(p) then
      fulfill_all_active_requests(p)
      i = i + 1
      if i > #players then i = 1 end
      break
    else
      i = i + 1
      if i > #players then i = 1 end
    end
    attempts = attempts + 1
  end

  storage[RR_NEXT_PLAYER_KEY] = i
end

return M
