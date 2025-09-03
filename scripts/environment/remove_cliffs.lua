-- scripts/environment/remove_cliffs.lua
-- This module removes cliff entities in a radius around the player.
-- The radius is provided by the GUI slider and confirmed via a green button.

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

  for _, cliff in pairs(player.surface.find_entities_filtered{area = area, type = "cliff"}) do
    if cliff.valid then
      cliff.destroy()
    end
  end

  player.print({"facc.remove-cliffs-msg", radius, radius})
end

return M
