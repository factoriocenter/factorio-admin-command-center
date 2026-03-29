-- scripts/utils/force_bonus_slider.lua
-- Shared helper for slider-driven LuaForce bonus fields.

local M = {}
local math_util = require("scripts/utils/flib_math")

--- Apply a slider bonus to a LuaForce numeric field while preserving the
--- underlying base value (e.g. research or other mods).
-- @param player LuaPlayer
-- @param old number
-- @param new number
-- @param field_name string
-- @param options table?
--        options.max_bonus number (default 1000)
--        options.min_value number (default 0)
--        options.max_value number? (optional hard cap)
--        options.integer boolean (default true)
-- @return boolean ok
-- @return number|string value_or_error
function M.apply(player, old, new, field_name, options)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return false, "not-allowed"
  end

  if type(field_name) ~= "string" or field_name == "" then
    return false, "invalid-field"
  end

  local opts = options or {}
  local max_bonus = tonumber(opts.max_bonus) or 1000
  local min_value = tonumber(opts.min_value) or 0
  local max_value = tonumber(opts.max_value)
  local integer = (opts.integer ~= false)

  local new_bonus = math_util.clamp_number(new, 0, max_bonus, 0)
  local previous_slider = math_util.clamp_number(old, 0, max_bonus, 0)

  local force = player.force
  local ok_current, current = pcall(function()
    return force[field_name]
  end)
  if not ok_current then
    return false, "field-read-failed"
  end

  current = tonumber(current) or 0

  -- Remove only the bonus this slider previously contributed.
  local max_removable = math_util.max(0, current - min_value)
  local applied_slider = math_util.min(previous_slider, max_removable)
  local base = current - applied_slider

  local result = base + new_bonus
  if result < min_value then
    result = min_value
  end
  if max_value and result > max_value then
    result = max_value
  end
  if integer then
    result = math_util.floor(result)
  end

  local ok_set = pcall(function()
    force[field_name] = result
  end)
  if not ok_set then
    return false, "field-write-failed"
  end

  return true, result
end

return M
