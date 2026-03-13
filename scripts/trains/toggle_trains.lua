-- File: scripts/trains/toggle_trains.lua
-- Toggle automatic/manual mode for all trains on the surface.

local M = {}

local function get_trains_for_player(player, surface)
  if not (player and player.valid and surface and surface.valid and game) then
    return {}
  end

  local force = player.force

  -- Factorio 2.x: prefer LuaTrainManager with explicit filter.
  if game.train_manager and game.train_manager.get_trains then
    local ok, result = pcall(function()
      return game.train_manager.get_trains({
        surface = surface,
        force = force
      })
    end)
    if ok and type(result) == "table" then
      return result
    end
  end

  -- Fallback for environments exposing force train queries.
  if force and force.get_trains then
    local ok, result = pcall(function()
      return force.get_trains(surface)
    end)
    if ok and type(result) == "table" then
      return result
    end
  end

  return {}
end

--- Toggles automatic mode for all trains.
-- @param player LuaPlayer
-- @param enabled boolean; true = automatic, false = manual
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local surface = player.surface
  local trains = get_trains_for_player(player, surface)

  for _, train in pairs(trains) do
    if train and train.valid then
      train.manual_mode = not enabled
    end
  end

  if enabled then
    player.print({ "facc.trains-automatic-activated" })
  else
    player.print({ "facc.trains-automatic-deactivated" })
  end
end

return M
