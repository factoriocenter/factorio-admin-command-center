-- scripts/cheats/research_targets.lua
-- Shared technology target lists for infinite-research cheats.

local M = {}

local SPACE_AGE_TARGETS = {
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

local BASE_TARGETS = {
  "laser-weapons-damage-7",
  "physical-projectile-damage-7",
  "refined-flammables-7",
  "stronger-explosives-7",
  "artillery-shell-range-1",
  "artillery-shell-speed-1",
  "worker-robots-speed-6",
  "mining-productivity-4",
  "follower-robot-count-5"
}

function M.get(space_age_enabled)
  if space_age_enabled then
    return SPACE_AGE_TARGETS
  end
  return BASE_TARGETS
end

return M
