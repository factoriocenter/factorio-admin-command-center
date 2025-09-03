-- scripts/cheats/instant_research.lua
-- Instant Research module: instantly completes any ongoing research when executed.

local M = {}

--- Instantly completes current research for the player's force.
-- @param player LuaPlayer object invoking the command.
function M.run(player)
  -- Permission check: allow only in single-player or for admins
  if not (not game.is_multiplayer() or player.admin) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  -- Loop until no current research remains
  while force.current_research do
    force.research_progress = 1
  end

  player.print({"facc.instant-research-success"})
end

return M
