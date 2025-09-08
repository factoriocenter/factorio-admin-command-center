-- scripts/mining/non_minable_permanent.lua
-- This module sets the 'minable' property to false for all entities
-- belonging to the player's force on all existing surfaces, making them non-minable permanently.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force

  -- Iterate over all surfaces in the game
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{force = force}) do
      if entity.valid and entity.minable ~= nil then
        entity.minable = false
      end
    end
  end

  player.print({"facc.minable-disabled-permanent"})
end

return M