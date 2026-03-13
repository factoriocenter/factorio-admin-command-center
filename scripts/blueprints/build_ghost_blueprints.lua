-- scripts/blueprint/build_ghost_blueprints.lua
-- This module builds all ghost entities and tile ghosts (excluding landfill).
-- Useful when players want to force placement of planned structures.

local M = {}
local flib_table = require("__flib__.table")

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force = player.force

  -- Revive entity ghosts
  flib_table.for_each(surface.find_entities_filtered{force = force, type = "entity-ghost"}, function(ghost)
    if ghost.valid then
      ghost.revive()
    end
  end)

  -- Revive tile ghosts (excluding landfill)
  local tiles_to_set = {}
  flib_table.for_each(surface.find_entities_filtered{type = "tile-ghost"}, function(tile)
    if tile.valid and tile.ghost_name ~= "landfill" then
      table.insert(tiles_to_set, {name = tile.ghost_name, position = tile.position})
    end
  end)

  if #tiles_to_set > 0 then
    surface.set_tiles(tiles_to_set)
  end

  player.print({"facc.build-blueprints-msg"})
end

return M
