-- scripts/cheats/high_infinite_research_levels.lua
-- Sets a predefined list of technologies to level 100 for the invoking player's force.

local M = {}

--- Sets each technology in the list to level 100.
-- @param player LuaPlayer – the player invoking the command
function M.run(player)
  -- Permission guard: only single-player or admins in multiplayer
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local tech_names = {
    "mining-productivity-3",
    "steel-plate-productivity",
    "laser-weapons-damage-7",
    "physical-projectile-damage-7",
    "low-density-structure-productivity",
    "artillery-shell-speed-1",
    "artillery-shell-damage-1",
    "artillery-shell-range-1",
    "plastic-bar-productivity",
    "rocket-fuel-productivity",
    "health",
    "refined-flammables-7",
    "stronger-explosives-7",
    "asteroid-productivity",
    "railgun-damage-1",
    "scrap-recycling-productivity",
    "processing-unit-productivity",
    "electric-weapons-damage-4",
    "worker-robots-speed-7",
    "rocket-part-productivity",
    "railgun-shooting-speed-1",
    "research-productivity",
    "follower-robot-count-5"
  }

  local force = player.force
  for _, name in ipairs(tech_names) do
    local tech = force.technologies[name]
    if tech then
      tech.level = 101
    end
  end

  player.print({"facc.high-infinite-research-levels-msg"})
end

return M
