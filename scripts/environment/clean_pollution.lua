-- scripts/automations/clean_pollution.lua
-- Clean Pollution automation: clears all pollution from the current surface

local M = {}

--- Executes pollution cleanup
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end
  player.surface.clear_pollution()
  player.print({ "facc.remove-pollution-msg" })
end

return M
