-- scripts/manufacturing/set_crafting_speed.lua
-- Live slider: adjusts manual crafting speed modifier via slider.
local M = {}

local MAX_BONUS = 1000
local MIN_MODIFIER = -1 -- LuaForce.manual_crafting_speed_modifier lower bound per Factorio API

local function clamp_slider(value)
  value = tonumber(value) or 0
  if value < 0 then return 0 end
  if value > MAX_BONUS then return MAX_BONUS end
  return value
end

--- Applies a new slider-based manual crafting speed modifier.
-- It removes the previous slider modifier and applies the new one,
-- ensuring that existing (e.g. research) modifiers are preserved.
-- @param player LuaPlayer - the invoking player
-- @param old number       - the previous modifier value applied by the slider
-- @param new number       — the new slider modifier to apply
function M.run(player, old, new)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  local current = force.manual_crafting_speed_modifier or 0

  local previous_slider = clamp_slider(old)
  local max_removable = math.max(0, current - MIN_MODIFIER)
  local applied_slider = math.min(previous_slider, max_removable)

  -- Remove old slider effect, preserving any existing modifiers (e.g. from research)
  local base = current - applied_slider

  -- Clamp between 0 and 1000, then re-apply without violating LuaForce bounds
  local slider_bonus = clamp_slider(new)
  local result = math.max(MIN_MODIFIER, base + slider_bonus)
  force.manual_crafting_speed_modifier = result
end

return M
