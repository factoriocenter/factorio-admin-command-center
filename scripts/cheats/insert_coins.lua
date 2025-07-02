-- scripts/cheats/insert_coins.lua
-- Inserts 100,000 coins into the player's inventory (no scenario check).
-- Modified: scenario gating removed so that coins can be inserted in any game mode.

local M = {}

--- Inserts coins into the player's inventory.
-- @param player LuaPlayer — the player invoking the command
function M.run(player)
    -- Permission guard: only single-player or admins in multiplayer
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end

    -- Always grant 100,000 coins unconditionally (scenario check removed)
    local inserted = player.insert{ name = "coin", count = 100000 }
    if inserted > 0 then
        player.print({"facc.insert-coins-granted"})
    else
        player.print({"facc.insert-coins-failed"})
    end
end

return M
