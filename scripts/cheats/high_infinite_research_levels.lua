-- scripts/cheats/high_infinite_research_levels.lua
-- Sets a predefined list of technologies to level 100 for the invoking player's force.
-- Adjusts the list depending on whether the Space-Age DLC is active.

local M = {}
local flib_technology = require("__flib__.technology")
local research_targets = require("scripts/cheats/research_targets")

local function is_multilevel(tech)
    local ok, result = pcall(flib_technology.is_multilevel, tech)
    return ok and result
end

--- Sets each technology in the list to level 100.
-- In Space-Age active: applies the full set of high-level researches.
-- Otherwise: applies a core subset of key technologies.
-- @param player LuaPlayer – the player invoking the command
function M.run(player)
    -- Permission guard: only single-player or admins in multiplayer
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end

    local force = player.force
    local space_age_enabled = script.active_mods["space-age"] ~= nil

    local tech_names = research_targets.get(space_age_enabled)

    -- Apply level override for each technology
    for _, name in ipairs(tech_names) do
        local tech = force.technologies[name]
        if tech and is_multilevel(tech) then
            tech.level = 101
        end
    end

    player.print({"facc.high-infinite-research-levels-msg"})
end

return M
