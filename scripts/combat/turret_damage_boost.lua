-- scripts/combat/turret_attack_boost.lua
-- Toggle turret attack bonus: add or remove a flat bonus to turret attack modifiers.

local M = {}

-- Flat bonus to be added/subtracted
local TURRET_CHEAT_BONUS = 1000

--- Toggles a flat attack bonus on a set of turret types.
-- @param player LuaPlayer – the invoking player
-- @param enabled boolean – true to apply bonus, false to remove it
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  local turret_types = {
    "gun-turret",
    "laser-turret",
    "flamethrower-turret",
    "artillery-turret",
    "rocket-turret",
    "tesla-turret",
    "railgun-turret"
  }

  for _, name in ipairs(turret_types) do
    local current = force.get_turret_attack_modifier(name) or 0
    if enabled then
      force.set_turret_attack_modifier(name, current + TURRET_CHEAT_BONUS)
    else
      force.set_turret_attack_modifier(name, current - TURRET_CHEAT_BONUS)
    end
  end

  if enabled then
    player.print({"facc.turret-damage-boost-activated"})
  else
    player.print({"facc.turret-damage-boost-deactivated"})
  end
end

return M
