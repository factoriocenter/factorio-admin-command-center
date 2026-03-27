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
local cached_supported_turret_types = nil

local function clamp_slider(value)
  return math_util.clamp_number(value, 0, MAX_BONUS, 0)
end

local function safe_get_turret_modifier(force, turret_name)
  local ok, result = pcall(force.get_turret_attack_modifier, force, turret_name)
  if not ok then
    return nil
  end
  return result or 0
end

local function safe_set_turret_modifier(force, turret_name, value)
  return pcall(force.set_turret_attack_modifier, force, turret_name, value)
end

local function get_supported_turret_types(force)
  if cached_supported_turret_types then
    return cached_supported_turret_types
  end

  local supported = {}
  for _, turret_name in ipairs(TURRET_TYPES) do
    if safe_get_turret_modifier(force, turret_name) ~= nil then
      supported[#supported + 1] = turret_name
    end
  end
  cached_supported_turret_types = supported
  return cached_supported_turret_types
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
  for _, turret in ipairs(get_supported_turret_types(force)) do
    local current = safe_get_turret_modifier(force, turret)
    if current ~= nil then
      local max_removable = math_util.max(0, current - MIN_MODIFIER)
      local applied_slider = math_util.min(previous_slider, max_removable)
      local base = current - applied_slider
      -- remove old, apply new without violating the API's -1 limit
      local result = math_util.max(MIN_MODIFIER, base + new_bonus)
      safe_set_turret_modifier(force, turret, result)
    end
  end
end

return M
