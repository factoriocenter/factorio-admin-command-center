-- scripts/map/hide_map.lua
-- This module uncharts all revealed chunks from the player's force perspective,
-- effectively hiding the entire map.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force = player.force

  for chunk in surface.get_chunks() do
    force.unchart_chunk({x = chunk.x, y = chunk.y}, surface)
  end

  player.print({"facc.hide-map-msg"})
end

return M
