-- scripts/character/toggle_editor_mode.lua
-- Toggle Editor Mode module: toggles the map editor for the player.
-- Only available in single-player or for admins in multiplayer.

local M = {}

--- Toggles the map editor mode for the invoking player.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end
  player.toggle_map_editor()
  player.print({ "facc.toggle-editor-msg" })
end

return M
