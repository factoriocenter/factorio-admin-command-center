-- scripts/automations/disable_friendly_fire.lua
-- Toggle friendly fire for the player's force

local M = {}

--- Toggles friendly fire for the player's force.
-- @param player LuaPlayer
-- @param enabled boolean; true to disable friendly fire, false to enable
function M.run(player, enabled)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end
    local force = player.force
    -- If 'enabled' is true, disable the friendly_fire
    force.friendly_fire = not enabled
    if enabled then
        player.print({"facc.disable-friendly-fire-activated"})
    else
        player.print({"facc.disable-friendly-fire-deactivated"})
    end
end

return M