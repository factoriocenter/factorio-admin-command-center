-- scripts/misc/ammo_to_turrets.lua
-- This module inserts uranium rounds (100 units) into empty gun turrets
-- that belong to the player's force.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force = player.force

  -- Find all gun turrets
  for _, turret in pairs(surface.find_entities_filtered{force = force, name = "gun-turret"}) do
    if turret.valid then
      local inventory = turret.get_inventory(defines.inventory.turret_ammo)
      if inventory and inventory.is_empty() then
        inventory.insert{name = "uranium-rounds-magazine", count = 100}
      end
    end
  end

  player.print({"facc.ammo-turrets-msg"})
end

return M
