-- scripts/combat/ammo_damage_boost.lua
-- Live slider: adjusts flat ammo damage bonus (0..1000).
-- Removes previous slider bonus before applying the new one.

local M = {}
local MAX_BONUS = 1000
local AMMO_TYPES = {
  "shotgun-shell", "cannon-shell", "artillery-shell", "rocket",
  "bullet", "railgun", "tesla", "laser", "grenade", "flamethrower", "capsule"
}

--- Applies a new ammo damage bonus based on slider movement.
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
  for _, ammo in ipairs(AMMO_TYPES) do
    local current = force.get_ammo_damage_modifier(ammo) or 0
    -- remove old, apply new
    force.set_ammo_damage_modifier(ammo, current - old + bonus)
  end
end

return M
