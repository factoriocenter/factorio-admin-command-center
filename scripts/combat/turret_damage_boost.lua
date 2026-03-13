-- scripts/combat/turret_damage_boost.lua
-- Live slider: adjusts flat turret attack bonus (0..1000).
-- Removes previous slider bonus before applying the new one.

local M = {}
local MAX_BONUS = 1000
local MIN_MODIFIER = -1 -- LuaForce.set_turret_attack_modifier lower bound
local math_util = require("scripts/utils/flib_math")
local TURRET_TYPES = {
  "gun-turret", "laser-turret", "flamethrower-turret",
  "artillery-turret", "rocket-turret", "tesla-turret", "railgun-turret"
}

local function clamp_slider(value)
  return math_util.clamp_number(value, 0, MAX_BONUS, 0)
end

--- Applies a new turret attack bonus based on slider movement.
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
  for _, turret in ipairs(TURRET_TYPES) do
    local current = force.get_turret_attack_modifier(turret) or 0
    local max_removable = math_util.max(0, current - MIN_MODIFIER)
    local applied_slider = math_util.min(previous_slider, max_removable)
    local base = current - applied_slider
    -- remove old, apply new without violating the API's -1 limit
    local result = math_util.max(MIN_MODIFIER, base + new_bonus)
    force.set_turret_attack_modifier(turret, result)
  end
end

return M
