-- scripts/map/remove_pollution.lua
-- This module removes all pollution from the player's current surface.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  player.surface.clear_pollution()
  player.print({"facc.remove-pollution-msg"})
end

return M
