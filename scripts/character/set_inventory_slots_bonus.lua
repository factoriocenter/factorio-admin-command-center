-- scripts/storage/set_inventory_slots_bonus.lua
-- Sets force inventory slots bonus with toolbelt-aware minimum guard.

local M = {}
local math_util = require("scripts/utils/flib_math")

local TOOLBELT_TECH = "toolbelt"
local TOOLBELT_MINIMUM = 10
local BASE_MINIMUM = 0
local MAX_BONUS = 65535

local function get_minimum_bonus(force)
  if not (force and force.valid) then
    return BASE_MINIMUM
  end
  local tech = force.technologies and force.technologies[TOOLBELT_TECH]
  if tech and tech.researched then
    return TOOLBELT_MINIMUM
  end
  return BASE_MINIMUM
end

--- Set force inventory slots bonus from a user-supplied value.
-- Returns the applied value on success.
-- Returns nil plus current minimum on invalid/minimum failure.
-- @param player LuaPlayer
-- @param raw_value any
-- @return number|nil, number minimum
function M.run(player, raw_value)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return nil, BASE_MINIMUM
  end

  local force = player.force
  if not (force and force.valid) then
    player.print({"facc.set-inventory-slots-bonus-invalid"})
    return nil, BASE_MINIMUM
  end

  local minimum = get_minimum_bonus(force)
  local n = tonumber(raw_value)
  if n == nil then
    player.print({"facc.set-inventory-slots-bonus-invalid"})
    return nil, minimum
  end

  local value = math.floor(n)
  if value < minimum then
    player.print({"facc.set-inventory-slots-bonus-minimum", minimum})
    return nil, minimum
  end

  value = math_util.clamp_number(value, minimum, MAX_BONUS, minimum)
  force.character_inventory_slots_bonus = value
  player.print({"facc.set-inventory-slots-bonus-msg", value})
  return value, minimum
end

return M
