-- scripts/automations/cheat_mode.lua
-- Toggle player cheat mode on or off

local M = {}

--- Toggles cheat mode for the player.
-- @param player LuaPlayer
-- @param enabled boolean; true to enable cheat mode, false to disable
function M.run(player, enabled)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end
    player.cheat_mode = enabled
    if enabled then
        player.print({"facc.cheat-mode-activated"})
    else
        player.print({"facc.cheat-mode-deactivated"})
    end
end

return M