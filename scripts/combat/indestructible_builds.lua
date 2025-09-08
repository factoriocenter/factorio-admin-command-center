-- scripts/combat/indestructible_builds.lua
-- Toggle destructibility of all existing entities belonging to the player’s force.

local M = {}

--- Apply or remove indestructibility on existing entities.
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
