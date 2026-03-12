-- scripts/cheats/add_infinite_research_levels.lua
-- Adds +100 levels to a predefined list of infinite technologies.
-- Uses LuaTechnology.level from runtime API.

local M = {}

local function get_target_technologies(space_age_enabled)
  if space_age_enabled then
    return {
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
  end

  return {
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
end

function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local force = player.force
  local space_age_enabled = script.active_mods["space-age"] ~= nil
  local tech_names = get_target_technologies(space_age_enabled)

  local updated = 0

  for _, name in ipairs(tech_names) do
    local tech = force.technologies[name]
    if tech then
      local current = tonumber(tech.level) or 1
      local ok = pcall(function()
        tech.level = current + 100
      end)
      if ok then
        updated = updated + 1
      end
    end
  end

  player.print({ "facc.add-infinite-research-levels-msg", updated })
end

return M
