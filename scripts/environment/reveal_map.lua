-- scripts/environment/reveal_map.lua
-- This module reveals a portion of the map centered on the player,
-- based on a radius defined by the GUI slider.

local M = {}
local area_util = require("scripts/utils/flib_area")

function M.run(player, radius)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local area = area_util.square_from_center(player.position, radius)

  player.force.chart(player.surface, area)

  player.print({"facc.reveal-map-msg", radius, radius})
end

return M
