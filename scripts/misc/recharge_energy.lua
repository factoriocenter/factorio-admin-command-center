-- scripts/misc/recharge_energy.lua
-- This module recharges all electric entities owned by the player's force
-- by setting their energy to maximum buffer capacity.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force = player.force

  for _, entity in pairs(surface.find_entities_filtered{force = force}) do
    if entity.valid and entity.energy and entity.electric_buffer_size then
      entity.energy = entity.electric_buffer_size
    end
  end

  player.print({"facc.recharge-energy-msg"})
end

return M
