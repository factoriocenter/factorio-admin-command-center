-- scripts/character/delete_ownerless_characters.lua
-- Delete Orphaned Characters module: deletes all character entities not controlled by any player.
-- Only available in single-player or for admins in multiplayer.

local M = {}

--- Deletes all orphaned character entities on the player's current surface.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local surface = player.surface
  local active_character = player.character

  for _, entity in pairs(surface.find_entities_filtered{ type = "character" }) do
    if entity.valid and entity ~= active_character then
      entity.destroy()
    end
  end

  player.print({ "facc.deleted-ownerless-msg" })
end

return M
