-- File: scripts/trains/toggle_trains.lua
-- Toggle automatic/manual mode for all trains on the surface.

local M = {}

--- Toggles automatic mode for all trains.
-- @param player LuaPlayer
-- @param enabled boolean; true = automatic, false = manual
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local surface = player.surface
  for _, loco in pairs(surface.find_entities_filtered{ name = "locomotive" }) do
    if loco.train and loco.train.valid then
      loco.train.manual_mode = not enabled
    end
  end

  if enabled then
    player.print({ "facc.trains-automatic-activated" })
  else
    player.print({ "facc.trains-automatic-deactivated" })
  end
end

return M