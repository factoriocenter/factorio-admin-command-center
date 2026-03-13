-- scripts/cheats/add_infinite_research_levels.lua
-- Adds +100 levels to a predefined list of infinite technologies.
-- Uses LuaTechnology.level from runtime API.

local M = {}
local flib_technology = require("__flib__.technology")
local research_targets = require("scripts/cheats/research_targets")

local function is_multilevel(tech)
  local ok, result = pcall(flib_technology.is_multilevel, tech)
  return ok and result
end

function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local force = player.force
  local space_age_enabled = script.active_mods["space-age"] ~= nil
  local tech_names = research_targets.get(space_age_enabled)

  local updated = 0

  for _, name in ipairs(tech_names) do
    local tech = force.technologies[name]
    if tech and is_multilevel(tech) then
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
