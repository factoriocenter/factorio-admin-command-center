-- scripts/blueprints/enable_ghost_on_death.lua
-- Enables automatic ghost creation on entity death for the player's force.
-- This is intended only before Construction robotics has been researched.

local M = {}

--- Enable ghost-on-death behavior (one-way action).
-- @param player LuaPlayer - the invoking player
function M.run(player)
  -- permission guard: only single-player or admins in multiplayer
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force = player.force
  local construction_robotics = force.technologies["construction-robotics"]
  if construction_robotics and construction_robotics.researched then
    player.print({"facc.ghost-on-death-tech-already-researched"})
    return
  end

  force.create_ghost_on_entity_death = true
  player.print({"facc.ghost-on-death-activated"})
end

return M
