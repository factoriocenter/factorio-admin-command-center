-- scripts/environment/disable_pollution.lua
-- Clear all existing pollution and toggle pollution generation

local M = {}
local flib_table = require("__flib__.table")

--- Clears all pollution and toggles new pollution generation globally.
-- @param player LuaPlayer
-- @param enabled boolean; true to disable pollution, false to enable pollution
function M.run(player, enabled)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end
    if enabled then
        -- Clear existing pollution
        flib_table.for_each(game.surfaces, function(surface)
            surface.clear_pollution()
        end)
        -- Disable new pollution
        game.map_settings.pollution.enabled = false
        player.print({"facc.disable-pollution-activated"})
    else
        -- Enable pollution
        game.map_settings.pollution.enabled = true
        player.print({"facc.disable-pollution-deactivated"})
    end
end

return M
