-- scripts/environment/remove_ground_items.lua
-- Module to remove all item entities (dropped items) from all surfaces.

local M = {}

--- Destroys every item-entity on all surfaces.
-- @param player LuaPlayer — the player invoking the action (for permission check and feedback)
function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Iterate through all surfaces and destroy every ground item
  for _, surface in pairs(game.surfaces) do
    for _, item_entity in pairs(surface.find_entities_filtered{ type = "item-entity" }) do
      if item_entity.valid then
        item_entity.destroy()
      end
    end
  end

  -- Notify the player
  player.print({ "facc.remove-ground-items-msg" })
end

return M
