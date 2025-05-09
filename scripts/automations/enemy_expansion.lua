-- scripts/automations/enemy_expansion.lua
-- Toggle enemy expansion (biter nest growth)
-- Switch ON: disable expansion; Switch OFF: enable expansion (default)

local M = {}

--- Toggles biter expansion globally.
-- @param player LuaPlayer
-- @param disable boolean; true to disable expansion, false to enable expansion
function M.run(player, disable)
    if not is_allowed(player) then
        player.print({ "facc.not-allowed" })
        return
    end

    -- When disable==true (switch ON), we set enabled = false; otherwise enabled = true
    game.map_settings.enemy_expansion.enabled = not disable

    if disable then
        -- user turned the switch ON → expansion is now disabled
        player.print({ "facc.enemy-expansion-deactivated" })
    else
        -- user turned the switch OFF → expansion is now enabled
        player.print({ "facc.enemy-expansion-activated" })
    end
end

return M
