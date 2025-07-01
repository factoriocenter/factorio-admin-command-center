-- scripts/map/remove_enemy_nests.lua
-- This module removes all enemy structures (spawners and worms) within a radius from the player.
-- The radius value is defined by the user through the GUI slider.

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

  for _, entity in pairs(player.surface.find_entities_filtered{
    area = area,
    force = "enemy"
  }) do
    if entity.valid then
      entity.destroy()
    end
  end

  player.print({"facc.remove-nests-msg", radius, radius})
end

return M
