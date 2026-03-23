-- scripts/character/set_inventory_slots_bonus.lua
-- Sets force inventory slots bonus with toolbelt-aware minimum guard.

local M = {}
local math_util = require("scripts/utils/flib_math")

local TOOLBELT_TECH = "toolbelt"
local TOOLBELT_MINIMUM = 10
local BASE_MINIMUM = 0
local MAX_BONUS = 65535

local function is_toolbelt_researched(force)
  if not (force and force.valid) then
    return false
  end
  local tech = force.technologies and force.technologies[TOOLBELT_TECH]
  return tech and tech.researched == true
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

  local toolbelt_researched = is_toolbelt_researched(force)
  local minimum = toolbelt_researched and TOOLBELT_MINIMUM or BASE_MINIMUM
  local n = tonumber(raw_value)
  if n == nil then
    player.print({"facc.set-inventory-slots-bonus-invalid"})
    return nil, minimum
  end

  local value = math.floor(n)
  if value < minimum then
    if toolbelt_researched then
      player.print({"facc.set-inventory-slots-bonus-minimum-toolbelt", minimum, {"technology-name." .. TOOLBELT_TECH}})
    else
      player.print({"facc.set-inventory-slots-bonus-minimum", minimum})
    end
    return nil, minimum
  end

  local clamped = math_util.clamp_number(value, minimum, MAX_BONUS, minimum)
  if clamped ~= value then
    player.print({"facc.set-inventory-slots-bonus-clamped-max", MAX_BONUS})
  end

  value = clamped
  force.character_inventory_slots_bonus = value
  player.print({"facc.set-inventory-slots-bonus-msg", value})
  return value, minimum
end

return M
