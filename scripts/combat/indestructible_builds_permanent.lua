-- scripts/combat/indestructible_builds_permanent.lua
-- This module sets the 'destructible' property to false for all entities
-- belonging to the player's force on all existing surfaces, making them indestructible permanently.

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
      if entity.valid and entity.destructible ~= nil then
        entity.destructible = false
      end
    end)
  end)

  player.print({"facc.indestructible-builds-permanent-msg"})
end

return M
