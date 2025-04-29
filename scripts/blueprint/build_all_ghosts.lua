-- scripts/blueprint/build_all_ghosts.lua
-- This module revives all ghost entities, tile ghosts (including landfill).
-- Intended for fully applying blueprint ghost layers.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force = player.force

  -- Revive entity ghosts
  for _, ghost in pairs(surface.find_entities_filtered{force = force, type = "entity-ghost"}) do
    if ghost.valid then
      ghost.revive()
    end
  end

  -- Revive tile ghosts (including landfill)
  local tiles_to_set = {}
  for _, tile in pairs(surface.find_entities_filtered{type = "tile-ghost"}) do
    if tile.valid then
      if tile.ghost_name == "landfill" then
        tile.revive() -- landfill treated like normal
      else
        table.insert(tiles_to_set, {name = tile.ghost_name, position = tile.position})
      end
    end
  end

  if #tiles_to_set > 0 then
    surface.set_tiles(tiles_to_set)
  end

  player.print({"facc.build-all-ghosts-msg"})
end

return M
