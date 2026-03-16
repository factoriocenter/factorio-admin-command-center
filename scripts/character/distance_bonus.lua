-- scripts/character/distance_bonus.lua
-- Shared slider applier for distance-related character bonuses.

local M = {}
local math_util = require("scripts/utils/flib_math")

local MAX_BONUS = 100

local function clamp_slider(value)
  return math_util.clamp_number(value, 0, MAX_BONUS, 0)
end

--- Applies a distance bonus slider to a LuaForce property.
-- Keeps external bonuses intact by removing previous slider contribution first.
-- @param player LuaPlayer
-- @param property string
-- @param old_slider number
-- @param new_slider number
function M.apply(player, property, old_slider, new_slider)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  if not (force and force.valid and type(property) == "string") then
    return
  end

  local ok_read, current = pcall(function()
    return force[property]
  end)
  if not ok_read then
    return
  end

  local old_bonus = clamp_slider(old_slider)
  local new_bonus = clamp_slider(new_slider)
  local base = (tonumber(current) or 0) - old_bonus
  local result = math_util.max(0, base + new_bonus)

  pcall(function()
    force[property] = result
  end)
end

return M
