-- scripts/automations/always_day.lua
-- Toggle eternal day on the player's current surface

local M = {}

local function is_allowed(player)
    return not game.is_multiplayer() or player.admin
end

--- Toggles an eternal day/night cycle.
-- @param player LuaPlayer
-- @param enabled boolean; true for always day, false to restore normal cycle
function M.run(player, enabled)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end
    local surface = player.surface
    surface.always_day = enabled
    if enabled then
        player.print({"facc.always-day-activated"})
    else
        player.print({"facc.always-day-deactivated"})
    end
end

return M