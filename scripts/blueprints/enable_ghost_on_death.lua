-- scripts/blueprints/enable_ghost_on_death.lua
-- When enabled, this module toggles automatic ghost creation
-- upon entity death for the player's force.
-- Useful for queuing up repair/build tasks before robots are unlocked.

local M = {}

--- Toggle ghost-on-death behavior.
-- @param player LuaPlayer – the invoking player
-- @param enabled boolean  – true to create ghosts on entity death, false to disable
function M.run(player, enabled)
  -- permission guard: only single-player or admins in multiplayer
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  force.create_ghost_on_entity_death = enabled

  if enabled then
    player.print({"facc.ghost-on-death-activated"})
  else
    player.print({"facc.ghost-on-death-deactivated"})
  end
end

return M
