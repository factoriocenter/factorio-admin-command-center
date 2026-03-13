-- scripts/environment/remove_cliffs.lua
-- This module removes cliff entities in a radius around the player.
-- The radius is provided by the GUI slider and confirmed via a green button.

local M = {}
local area_util = require("scripts/utils/flib_area")
local flib_table = require("__flib__.table")

function M.run(player, radius)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local area = area_util.square_from_center(player.position, radius)

  flib_table.for_each(player.surface.find_entities_filtered{area = area, type = "cliff"}, function(cliff)
    if cliff.valid then
      cliff.destroy()
    end
  end)

  player.print({"facc.remove-cliffs-msg", radius, radius})
end

return M
