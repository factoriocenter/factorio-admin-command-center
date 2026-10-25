-- 2.1 teleport moves only the camera in remote view. exit_remote_view exists
-- in both supported versions, but can fail on platforms or during rocket travel.
local M = {}

function M.prepare_player(player)
  if player.controller_type == defines.controllers.remote then
    player.exit_remote_view()
    -- Do not report a camera move as a successful character teleport.
    return player.controller_type ~= defines.controllers.remote
  end
  return true
end

return M
