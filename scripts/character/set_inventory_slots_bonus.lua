-- scripts/character/set_inventory_slots_bonus.lua
-- Sets force inventory slots bonus (delta style) with toolbelt-aware minimum guard.

local M = {}
local math_util = require("scripts/utils/flib_math")
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

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
-- Uses old/new delta semantics to preserve research/base value.
-- Returns the applied total value on success.
-- Returns nil plus current minimum on invalid/minimum failure.
-- @param player LuaPlayer
-- @param old_value any
-- @param raw_value any
-- @return number|nil, number minimum, number|nil applied_bonus
function M.run(player, old_value, raw_value)
  if raw_value == nil then
    raw_value = old_value
    old_value = 0
  end

  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return nil, BASE_MINIMUM, nil
  end

  local force = player.force
  if not (force and force.valid) then
    player.print({"facc.set-inventory-slots-bonus-invalid"})
    return nil, BASE_MINIMUM, nil
  end

  local toolbelt_researched = is_toolbelt_researched(force)
  local minimum = toolbelt_researched and TOOLBELT_MINIMUM or BASE_MINIMUM
  local n = tonumber(raw_value)
  if n == nil then
    player.print({"facc.set-inventory-slots-bonus-invalid"})
    return nil, minimum, nil
  end

  local new_bonus = math.floor(n)
  local old_bonus = math.floor(tonumber(old_value) or 0)

  local clamped_new = math_util.clamp_number(new_bonus, 0, MAX_BONUS, 0)
  if clamped_new ~= new_bonus then
    player.print({"facc.set-inventory-slots-bonus-clamped-max", MAX_BONUS})
  end
  local clamped_old = math_util.clamp_number(old_bonus, 0, MAX_BONUS, 0)

  local ok, result = force_bonus_slider.apply(player, clamped_old, clamped_new, "character_inventory_slots_bonus", {
    max_bonus = MAX_BONUS,
    min_value = minimum,
    max_value = MAX_BONUS,
    integer = true
  })

  if not ok then
    player.print({"facc.runtime-compat-error", "facc_set_inventory_slots_bonus"})
    return nil, minimum, nil
  end

  player.print({"facc.set-inventory-slots-bonus-msg", result})
  return result, minimum, clamped_new
end

return M
