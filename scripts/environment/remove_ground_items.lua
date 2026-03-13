-- scripts/environment/remove_ground_items.lua
-- Module to remove all item entities (dropped items) from all surfaces.

local M = {}
local flib_table = require("__flib__.table")

--- Destroys every item-entity on all surfaces.
-- @param player LuaPlayer — the player invoking the action (for permission check and feedback)
function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Iterate through all surfaces and destroy every ground item
  flib_table.for_each(game.surfaces, function(surface)
    flib_table.for_each(surface.find_entities_filtered{ type = "item-entity" }, function(item_entity)
      if item_entity.valid then
        item_entity.destroy()
      end
    end)
  end)

  -- Notify the player
  player.print({ "facc.remove-ground-items-msg" })
end

return M
