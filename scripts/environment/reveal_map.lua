-- scripts/environment/reveal_map.lua
-- This module reveals a portion of the map centered on the player,
-- based on a radius defined by the GUI slider.

local M = {}

function M.run(player, radius)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local pos = player.position
  local area = {
    {pos.x - radius, pos.y - radius},
    {pos.x + radius, pos.y + radius}
  }

  player.force.chart(player.surface, area)

  player.print({"facc.reveal-map-msg", radius, radius})
end

return M
