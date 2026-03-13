-- scripts/mining/toggle_minable.lua
-- Toggles all existing entities on the current surface between minable/non-minable.

local M = {}
local flib_table = require("__flib__.table")

--- Toggles whether entities belonging to the player’s force can be mined.
-- @param player LuaPlayer
-- @param enabled boolean; true → make all non-minable, false → make all minable
function M.run(player, enabled)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end
    local surface = player.surface
    local force   = player.force

    flib_table.for_each(surface.find_entities_filtered{force = force}, function(e)
        if e.valid then
            -- when switch is ON (enabled==true), set minable=false
            -- when switch is OFF (enabled==false), set minable=true
            e.minable = not enabled
        end
    end)

    if enabled then
        player.print({"facc.minable-disabled"})
    else
        player.print({"facc.minable-enabled"})
    end
end

return M
