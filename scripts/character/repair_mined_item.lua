-- scripts/character/repair_mined_item.lua
-- Personal cheat: repair entities to max health right before mining.

local M = {}
local flib_table = require("__flib__.table")

local ENABLED_PLAYERS_KEY = "facc_repair_mined_item_enabled_players"

local function ensure_enabled_players()
  return flib_table.get_or_insert(storage, ENABLED_PLAYERS_KEY, {})
end

function M.is_player_enabled(player_index)
  local enabled_players = ensure_enabled_players()
  return enabled_players[player_index] == true
end

function M.toggle_player(player, enable)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local enabled_players = ensure_enabled_players()
  enabled_players[player.index] = (enable == true)

  if enable then
    player.print({"facc.repair-mined-item-enabled"})
  else
    player.print({"facc.repair-mined-item-disabled"})
  end
end

function M.on_pre_player_mined_item(event)
  if not (event and event.player_index and M.is_player_enabled(event.player_index)) then
    return
  end

  local entity = event.entity
  if not (entity and entity.valid and entity.health ~= nil and entity.prototype) then
    return
  end

  local max_health
  local ok, value = pcall(function()
    if entity.quality then
      return entity.prototype.get_max_health(entity.quality)
    end
    return entity.prototype.get_max_health()
  end)
  if ok then
    max_health = tonumber(value)
  end

  if not (max_health and max_health > 0) then
    return
  end

  if (entity.health or 0) < max_health then
    entity.health = max_health
  end
end

return M
