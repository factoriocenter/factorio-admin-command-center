-- scripts/enemies/remove_enemy_nests.lua
-- This module removes all enemy structures (spawners and worms) within a radius from the player.
-- The radius value is defined by the user through the GUI slider.

local M = {}
local area_util = require("scripts/utils/flib_area")
local flib_table = require("__flib__.table")

function M.run(player, radius)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local area = area_util.square_from_center(player.position, radius)

  flib_table.for_each(player.surface.find_entities_filtered{
    area = area,
    force = "enemy"
  }, function(entity)
    if entity.valid then
      entity.destroy()
    end
  end)

  player.print({"facc.remove-nests-msg", radius, radius})
end

return M
