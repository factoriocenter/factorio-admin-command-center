-- scripts/automations/clean_pollution.lua
-- Clean Pollution automation: clears all pollution from the current surface

local M = {}

--- Permission check: allow in single-player or for admins
-- @param player LuaPlayer invoking the command
-- @return boolean
local function is_allowed(player)
  return not game.is_multiplayer() or player.admin
end

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
