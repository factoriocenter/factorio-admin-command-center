-- scripts/cheats/set_game_speed.lua
-- Allows admins to set the global game speed via slider.
-- @param player LuaPlayer — the invoking player
-- @param speed number     — desired game speed (clamped 0.25..64)
local M = {}

--- Runs the speed change.
-- Checks permissions, clamps the value, applies and notifies the player.
-- @param player LuaPlayer
-- @param speed number
function M.run(player, speed)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end
  -- Clamp speed between 0.25 and 64
  local s = math.max(0.25, math.min(speed, 64))
  game.speed = s
  -- player.print({"facc.set-game-speed-msg", s})
end

return M
