-- scripts/combat/ammo_damage_boost.lua
-- Live slider: adjusts flat ammo damage bonus (0..1000).
-- Removes previous slider bonus before applying the new one.

local M = {}
local MAX_BONUS = 1000
local MIN_MODIFIER = -1 -- LuaForce.set_ammo_damage_modifier lower bound
local math_util = require("scripts/utils/flib_math")
local AMMO_TYPES = {
  "shotgun-shell", "cannon-shell", "artillery-shell", "rocket",
  "bullet", "railgun", "tesla", "laser", "grenade", "flamethrower", "capsule"
}

local function clamp_slider(value)
  return math_util.clamp_number(value, 0, MAX_BONUS, 0)
end

--- Applies a new ammo damage bonus based on slider movement.
-- @param player LuaPlayer - the invoking player
-- @param old number       - the previous slider value
-- @param new number       - the new slider value
function M.apply(player, old, new)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local new_bonus = clamp_slider(new)
  local previous_slider = clamp_slider(old)

  local force = player.force
  for _, ammo in ipairs(AMMO_TYPES) do
    local current = force.get_ammo_damage_modifier(ammo) or 0
    local max_removable = math_util.max(0, current - MIN_MODIFIER)
    local applied_slider = math_util.min(previous_slider, max_removable)
    local base = current - applied_slider
    -- remove old, apply new without crossing the API's -1 lower bound
    local result = math_util.max(MIN_MODIFIER, base + new_bonus)
    force.set_ammo_damage_modifier(ammo, result)
  end
end

return M
