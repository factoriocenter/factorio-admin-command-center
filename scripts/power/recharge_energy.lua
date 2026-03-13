-- scripts/power/recharge_energy.lua
-- This module recharges:
--   • electric entities (machines, accumulators, etc.) of the player's force
--   • the player's personal equipment grid
--   • all spidertrons of the force
--   • all tanks of the force

local M = {}
local flib_table = require("__flib__.table")

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force   = player.force

  -- 1) Recharge all electric entities belonging to the force
  flib_table.for_each(surface.find_entities_filtered{force = force}, function(entity)
    if entity.valid and entity.energy and entity.electric_buffer_size then
      entity.energy = entity.electric_buffer_size
    end
  end)

  -- 2) Recharge player's equipment grid
  if player.character and player.character.grid then
    for _, eq in pairs(player.character.grid.equipment) do
      if eq.valid and eq.energy and eq.max_energy then
        eq.energy = eq.max_energy
      end
    end
  end

  -- 3) Recharge all spidertron equipment grids
  flib_table.for_each(surface.find_entities_filtered{name = "spidertron", force = force}, function(spider)
    if spider.valid and spider.grid then
      flib_table.for_each(spider.grid.equipment, function(eq)
        if eq.valid and eq.energy and eq.max_energy then
          eq.energy = eq.max_energy
        end
      end)
    end
  end)

  -- 4) Recharge all tank equipment grids
  flib_table.for_each(surface.find_entities_filtered{name = "tank", force = force}, function(tank)
    if tank.valid and tank.grid then
      flib_table.for_each(tank.grid.equipment, function(eq)
        if eq.valid and eq.energy and eq.max_energy then
          eq.energy = eq.max_energy
        end
      end)
    end
  end)

  player.print({"facc.recharge-energy-msg"})
end

return M
