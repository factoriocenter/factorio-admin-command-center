-- scripts/combat/ammo_damage_boost.lua
-- Toggle ammo damage cheat: add or remove a flat bonus to various ammo types.

local M = {}

-- Flat bonus to be added/subtracted
local AMMO_CHEAT_BONUS = 1000

--- Toggles a flat damage bonus for a set of ammo types.
-- @param player LuaPlayer – the invoking player
-- @param enabled boolean – true to add bonus, false to remove it
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  local ammo_types = {
    "shotgun-shell", "cannon-shell", "artillery-shell", "rocket",
    "bullet", "railgun", "tesla", "laser", "grenade", "flamethrower", "capsule"
  }

  for _, name in ipairs(ammo_types) do
    local current = force.get_ammo_damage_modifier(name) or 0
    if enabled then
      force.set_ammo_damage_modifier(name, current + AMMO_CHEAT_BONUS)
    else
      force.set_ammo_damage_modifier(name, current - AMMO_CHEAT_BONUS)
    end
  end

  if enabled then
    player.print({"facc.ammo-damage-boost-activated"})
  else
    player.print({"facc.ammo-damage-boost-deactivated"})
  end
end

return M
