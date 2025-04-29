-- scripts/blueprint/upgrade_blueprints_to_legendary.lua
-- This module upgrades all blueprints in the player's inventory and blueprint books to legendary quality.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local inv = player.get_main_inventory()
  local total = 0

  -- Function to upgrade a blueprint
  local function upgrade_blueprint(bp)
    local ents = bp.get_blueprint_entities()
    if ents then
      for _, e in pairs(ents) do
        if e.name then
          e.quality = "legendary"
        end
      end
      bp.set_blueprint_entities(ents)
      total = total + 1
    end
  end

  -- Recursive function to scan items
  local function scan_item(item)
    if item.valid_for_read then
      if item.is_blueprint then
        upgrade_blueprint(item)
      elseif item.is_blueprint_book then
        local book_inv = item.get_inventory(defines.inventory.item_main)
        if book_inv then
          for i = 1, #book_inv do
            scan_item(book_inv[i])
          end
        end
      end
    end
  end

  for i = 1, #inv do
    scan_item(inv[i])
  end

  if total > 0 then
    player.print({"facc.upgraded-blueprints-msg", total})
  else
    player.print({"facc.no-blueprints-found-msg"})
  end
end

return M