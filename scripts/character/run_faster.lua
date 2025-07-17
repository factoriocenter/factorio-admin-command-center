-- scripts/character/run_faster.lua
-- Live slider: adjusts the player's running speed modifier (0..10)

local M = {}

--- Sets the character running speed modifier.
-- @param player LuaPlayer – the invoking player
-- @param speed  number    – slider value (0..10)
function M.run(player, speed)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end
  -- Clamp speed between 0 and 10
  local s = math.max(0, math.min(speed, 10))
  player.character_running_speed_modifier = s
end

return M
