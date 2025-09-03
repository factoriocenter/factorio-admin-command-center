-- scripts/mining/set_mining_speed.lua
-- Allows admins to set manual mining speed modifier via slider.
-- @param player LuaPlayer      — the invoking player
-- @param modifier number       — mining speed modifier (0..1000)
local M = {}

--- Runs the mining speed change.
-- Checks permissions, clamps the value, applies and notifies the player.
-- @param player LuaPlayer
-- @param modifier number
function M.run(player, modifier)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end
  -- Clamp between 0 and 1000
  local m = math.max(0, math.min(modifier, 1000))
  local force = player.force
  force.manual_mining_speed_modifier = m
  -- player.print({"facc.set-mining-speed-msg", m})
end

return M
