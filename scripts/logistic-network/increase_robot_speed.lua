-- scripts/logistic-network/increase_robot_speed.lua
-- Toggle worker robots speed bonus on the force

local M = {}
local WORKER_CHEAT_BONUS = 50

--- Runs the speed cheat for worker robots.
-- @param player LuaPlayer — the invoking player
-- @param enabled boolean — true to add bonus, false to remove bonus
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local force = player.force
  local current = force.worker_robots_speed_modifier or 0

  if enabled then
    force.worker_robots_speed_modifier = current + WORKER_CHEAT_BONUS
    player.print({ "facc.increase-robot-speed-activated", WORKER_CHEAT_BONUS })
  else
    force.worker_robots_speed_modifier = current - WORKER_CHEAT_BONUS
    player.print({ "facc.increase-robot-speed-deactivated", WORKER_CHEAT_BONUS })
  end
end

return M
