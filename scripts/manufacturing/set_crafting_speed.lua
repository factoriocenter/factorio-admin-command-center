-- File: scripts/manufacturing/set_crafting_speed.lua
-- Allows admins to set manual crafting speed modifier via slider.
-- @param player LuaPlayer      — the invoking player
-- @param modifier number       — crafting speed modifier (0..1000)
local M = {}

--- Runs the crafting speed change.
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
  force.manual_crafting_speed_modifier = m
  -- player.print({"facc.set-crafting-speed-msg", m})
end

return M
