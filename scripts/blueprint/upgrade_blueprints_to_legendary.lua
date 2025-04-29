-- scripts/blueprint/upgrade_blueprints_to_legendary.lua
-- Scans the player’s main inventory (including nested blueprint books)
-- and upgrades every blueprint entity definition to legendary quality.
-- Prints a summary of how many blueprints were modified, or a warning if none found.

local M = {}

--- Runs the upgrade process.
-- @param player LuaPlayer object invoking the command.
function M.run(player)
  -- Permission check: only allow in single-player or for admins
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Attempt to get the player's main inventory; may be nil in editor mode
  local inv = player.get_main_inventory()
  if not inv then
    -- No valid main inventory found, abort
    player.print({"facc.no-blueprints-found-msg"})
    return
  end

  local total_upgraded = 0

  --- Upgrades all entities in a blueprint stack to legendary quality.
  -- @param bp LuaItemStack containing a blueprint.
  local function upgrade_blueprint(bp)
    local entities = bp.get_blueprint_entities()
    if entities then
      for _, ent in pairs(entities) do
        if ent.name then
          ent.quality = "legendary"
        end
      end
      bp.set_blueprint_entities(entities)
      total_upgraded = total_upgraded + 1
    end
  end

  --- Recursively scans an item stack for blueprints or blueprint books.
  -- @param item LuaItemStack to inspect.
  local function scan_item(item)
    if not item.valid_for_read then
      return
    end

    if item.is_blueprint then
      -- Single blueprint: upgrade it directly
      upgrade_blueprint(item)

    elseif item.is_blueprint_book then
      -- Blueprint book: iterate its internal inventory
      local book_inv = item.get_inventory(defines.inventory.item_main)
      if book_inv then
        for slot = 1, #book_inv do
          scan_item(book_inv[slot])
        end
      end
    end
  end

  -- Iterate every slot in the main inventory
  for slot = 1, #inv do
    scan_item(inv[slot])
  end

  -- Output result
  if total_upgraded > 0 then
    player.print({"facc.upgraded-blueprints-msg", total_upgraded})
  else
    player.print({"facc.no-blueprints-found-msg"})
  end
end

return M
