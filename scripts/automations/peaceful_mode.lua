-- scripts/automations/peaceful_mode.lua
-- Toggle peaceful mode (no biter attacks unless provoked)

local M = {}

--- Toggles peaceful mode on the player's surface.
-- @param player LuaPlayer
-- @param enabled boolean; true to enable peaceful mode, false to disable
function M.run(player, enabled)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end
    local surface = player.surface
    surface.peaceful_mode = enabled
    if enabled then
        player.print({"facc.peaceful-mode-activated"})
    else
        player.print({"facc.peaceful-mode-deactivated"})
    end
end

return M