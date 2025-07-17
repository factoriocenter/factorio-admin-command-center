-- scripts/logistic-network/increase_robot_speed.lua
-- Live slider: adjusts worker robots speed bonus based on GUI slider movements.

local M = {}
local MAX_BONUS = 50

--- Applies a new slider-based speed bonus for worker robots.
-- It removes the previous slider bonus and applies the new one,
-- ensuring that existing (e.g. research) bonuses are preserved.
-- @param player LuaPlayer — the invoking player
-- @param old number       — the previous bonus value applied by the slider
-- @param new number       — the new slider bonus to apply
function M.apply(player, old, new)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  local current = force.worker_robots_speed_modifier or 0

  -- Remove old slider effect, preserving any existing bonuses (e.g. from research)
  local base = current - old

  -- Clamp the slider bonus itself within [0, MAX_BONUS]
  local slider_bonus = math.max(0, math.min(new, MAX_BONUS))

  -- Apply base + new slider bonus
  force.worker_robots_speed_modifier = base + slider_bonus
end

return M
