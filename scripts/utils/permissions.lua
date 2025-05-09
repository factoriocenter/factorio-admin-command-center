-- scripts/utils/permissions.lua
-- Centralized permission check for the Factorio Admin Command Center (FACC).
--
-- Only players in single-player or admins in multiplayer may use FACC features.

local M = {}

--- Returns true if `player` is allowed to use admin commands.
-- @param player LuaPlayer
-- @treturn boolean
function M.is_allowed(player)
  return player and (not game.is_multiplayer() or player.admin)
end

return M
