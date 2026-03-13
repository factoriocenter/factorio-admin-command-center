-- scripts/mining/non_minable_permanent.lua
-- This module sets the 'minable' property to false for all entities
-- belonging to the player's force on all existing surfaces, making them non-minable permanently.

local M = {}
local flib_table = require("__flib__.table")

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force

  -- Iterate over all surfaces in the game
  flib_table.for_each(game.surfaces, function(surface)
    flib_table.for_each(surface.find_entities_filtered{force = force}, function(entity)
      if entity.valid and entity.minable ~= nil then
        entity.minable = false
      end
    end)
  end)

  player.print({"facc.minable-disabled-permanent"})
end

return M
