-- scripts/misc/repair_and_rebuild.lua
-- Instantly repairs all damaged entities and revives all ghosts for the player's force.

local M = {}

function M.run(player)
    -- Permission check: allow in singleplayer or if admin in multiplayer
    if not (not game.is_multiplayer() or player.admin) then
        player.print({"facc.not-allowed"})
        return
    end

    local surface = player.surface
    local force   = player.force

    -- Instantly restore health of every entity belonging to the force
    for _, ent in ipairs(surface.find_entities_filtered{force = force}) do
        if ent.valid and ent.health then
            -- set health to a very large value (effectively maxed out)
            ent.health = 1e9
        end
    end

    -- Revive all entity ghosts
    for _, ghost in ipairs(surface.find_entities_filtered{force = force, type = "entity-ghost"}) do
        if ghost.valid then
            ghost.revive()
        end
    end

    -- Revive all tile ghosts (including landfill)
    for _, tile in ipairs(surface.find_entities_filtered{force = force, type = "tile-ghost"}) do
        if tile.valid then
            if tile.ghost_name == "landfill" then
                tile.revive()
            else
                surface.set_tiles{{ name = tile.ghost_name, position = tile.position }}
            end
        end
    end

    player.print({"facc.repair-rebuild-msg"})
end

return M
