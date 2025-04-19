-- scripts/character/toggle_editor_mode.lua
local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print{"facc.not-allowed"}
    return
  end
  player.toggle_map_editor()
  player.print{"facc.toggle-editor-msg"}
end

return M
