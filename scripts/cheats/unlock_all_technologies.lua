-- scripts/cheats/unlock_all_technologies.lua
-- This module completes all technologies for the player's force instantly.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  player.force.research_all_technologies()
  player.print({"facc.unlock-technologies-msg"})
end

return M
