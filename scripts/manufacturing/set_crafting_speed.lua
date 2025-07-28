-- scripts/manufacturing/set_crafting_speed.lua
-- Live slider: adjusts manual crafting speed modifier via slider.
local M = {}

--- Applies a new slider-based manual crafting speed modifier.
-- It removes the previous slider modifier and applies the new one,
-- ensuring that existing (e.g. research) modifiers are preserved.
-- @param player LuaPlayer — the invoking player
-- @param old number       — the previous modifier value applied by the slider
-- @param new number       — the new slider modifier to apply
function M.run(player, old, new)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  local current = force.manual_crafting_speed_modifier or 0

  -- Remove old slider effect, preserving any existing modifiers (e.g. from research)
  local base = current - old

  -- Clamp between 0 and 1000
  local slider_bonus = math.max(0, math.min(new, 1000))
  force.manual_crafting_speed_modifier = base + slider_bonus

  -- Apply base + new slider bonus
  force.manual_crafting_speed_modifier = base + slider_bonus
end

return M
