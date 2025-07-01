-- scripts/automations/indestructible_builds.lua
-- Toggle destructibility of all existing entities belonging to the player’s force.
-- When the switch is ON (enabled = true), all existing entities become indestructible (destructible = false).
-- When the switch is OFF (enabled = false), all those entities revert to normal (destructible = true).
--
-- Note: Only entities present at the moment you flip the switch are affected. New entities built afterward
-- will remain in their default state until you toggle the switch again.

local M = {}

--- Apply or remove indestructibility on existing entities.
-- @param player LuaPlayer
-- @param enabled boolean; true when switch ON (make indestructible), false when switch OFF (make destructible)
function M.run(player, enabled)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end

    local surface = player.surface
    local force   = player.force

    -- Iterate through all entities of this force on the current surface
    for _, entity in pairs(surface.find_entities_filtered{ force = force }) do
        if entity.valid and entity.destructible ~= nil then
            -- When enabled == true (switch ON), set destructible = false.
            -- When enabled == false (switch OFF), set destructible = true.
            entity.destructible = not enabled
        end
    end

    if enabled then
        player.print({"facc.indestructible-activated"})     -- You should add these localization keys
    else
        player.print({"facc.indestructible-deactivated"})
    end
end

return M
