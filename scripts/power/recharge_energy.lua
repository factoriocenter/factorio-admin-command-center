-- scripts/power/recharge_energy.lua
-- This module recharges:
--   • electric entities (machines, accumulators, etc.) of the player's force
--   • the player's personal equipment grid
--   • all spidertrons of the force
--   • all tanks of the force

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force   = player.force

  -- 1) Recharge all electric entities belonging to the force
  for _, entity in pairs(surface.find_entities_filtered{force = force}) do
    if entity.valid and entity.energy and entity.electric_buffer_size then
      entity.energy = entity.electric_buffer_size
    end
  end

  -- 2) Recharge player's equipment grid
  if player.character and player.character.grid then
    for _, eq in pairs(player.character.grid.equipment) do
      if eq.valid and eq.energy and eq.max_energy then
        eq.energy = eq.max_energy
      end
    end
  end

  -- 3) Recharge all spidertron equipment grids
  for _, spider in pairs(surface.find_entities_filtered{name = "spidertron", force = force}) do
    if spider.valid and spider.grid then
      for _, eq in pairs(spider.grid.equipment) do
        if eq.valid and eq.energy and eq.max_energy then
          eq.energy = eq.max_energy
        end
      end
    end
  end

  -- 4) Recharge all tank equipment grids
  for _, tank in pairs(surface.find_entities_filtered{name = "tank", force = force}) do
    if tank.valid and tank.grid then
      for _, eq in pairs(tank.grid.equipment) do
        if eq.valid and eq.energy and eq.max_energy then
          eq.energy = eq.max_energy
        end
      end
    end
  end

  player.print({"facc.recharge-energy-msg"})
end

return M
