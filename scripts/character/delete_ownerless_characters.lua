-- scripts/character/delete_ownerless_characters.lua
-- This module deletes all orphaned character entities that are not controlled by any player.
-- Useful for cleaning up unused character corpses or duplicates.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local active_character = player.character

  for _, entity in pairs(surface.find_entities_filtered{type = "character"}) do
    if entity.valid and entity ~= active_character then
      entity.destroy()
    end
  end

  player.print({"facc.deleted-ownerless-msg"})
end

return M
