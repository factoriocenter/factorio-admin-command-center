-- scripts/combat/turret_damage_boost.lua
-- Live slider: adjusts flat turret attack bonus (0..1000).
-- Removes previous slider bonus before applying the new one.

local M = {}
local MAX_BONUS = 1000
local TURRET_TYPES = {
  "gun-turret", "laser-turret", "flamethrower-turret",
  "artillery-turret", "rocket-turret", "tesla-turret", "railgun-turret"
}

--- Applies a new turret attack bonus based on slider movement.
-- @param player LuaPlayer – the invoking player
-- @param old number       – the previous slider value
-- @param new number       – the new slider value
function M.apply(player, old, new)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Clamp slider value
  local bonus = math.max(0, math.min(new, MAX_BONUS))

  local force = player.force
  for _, turret in ipairs(TURRET_TYPES) do
    local current = force.get_turret_attack_modifier(turret) or 0
    -- remove old, apply new
    force.set_turret_attack_modifier(turret, current - old + bonus)
  end
end

return M
