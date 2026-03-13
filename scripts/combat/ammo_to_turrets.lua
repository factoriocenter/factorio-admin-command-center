-- scripts/combat/ammo_to_turrets.lua
-- Inserts appropriate ammo into empty turrets:
--   • gun-turret       → uranium-rounds-magazine (100)
--   • artillery-turret → artillery-shell (5)
--   • rocket-turret    → rocket (100) [Space Age only]
--   • railgun-turret   → railgun-ammo (10) [Space Age only]

local M = {}
local flib_table = require("__flib__.table")

-- Detect whether the Space Age DLC/mod is active
local space_age_enabled = script.active_mods["space-age"] ~= nil

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force   = player.force

  -- Gun turret
  flib_table.for_each(surface.find_entities_filtered{force = force, name = "gun-turret"}, function(turret)
    if turret.valid then
      local inv = turret.get_inventory(defines.inventory.turret_ammo)
      if inv and inv.is_empty() then
        inv.insert{name = "uranium-rounds-magazine", count = 100}
      end
    end
  end)

  -- Artillery turret
  flib_table.for_each(surface.find_entities_filtered{force = force, name = "artillery-turret"}, function(turret)
    if turret.valid then
      local inv = turret.get_inventory(defines.inventory.turret_ammo)
      if inv and inv.is_empty() then
        inv.insert{name = "artillery-shell", count = 5}
      end
    end
  end)

  if space_age_enabled then
    -- Rocket turret (Space Age)
    flib_table.for_each(surface.find_entities_filtered{force = force, name = "rocket-turret"}, function(turret)
      if turret.valid then
        local inv = turret.get_inventory(defines.inventory.turret_ammo)
        if inv and inv.is_empty() then
          inv.insert{name = "rocket", count = 100}
        end
      end
    end)

    -- Railgun turret (Space Age)
    flib_table.for_each(surface.find_entities_filtered{force = force, name = "railgun-turret"}, function(turret)
      if turret.valid then
        local inv = turret.get_inventory(defines.inventory.turret_ammo)
        if inv and inv.is_empty() then
          inv.insert{name = "railgun-ammo", count = 10}
        end
      end
    end)
  end

  player.print({"facc.ammo-turrets-msg"})
end

return M
