-- scripts/character/convert_inventory_to_legendary.lua
-- Converts all items in the player's inventory, weapons, ammo, armor, and equipment to legendary quality
-- Ignores blueprints, blueprint books, and both vanilla planners (upgrade and deconstruction)

local M = {}

--- Runs the conversion to legendary quality.
-- Checks for valid player.character before proceeding.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Guard: ensure player has a character (avoid "No character" error)
  if not player.character then
    player.print("No character present to convert inventory.")
    return
  end

  -- Temporarily increase inventory slots to prevent overflow
  local original_bonus = player.character_inventory_slots_bonus or 0
  player.character_inventory_slots_bonus = original_bonus + 1000

  -- Safely insert item into inventory or store in a chest
  local function safe_insert_or_store(item)
    if player.can_insert(item) then
      player.insert(item)
    else
      local chest = player.surface.find_entity("steel-chest", player.position)
      if not chest then
        chest = player.surface.create_entity{
          name = "steel-chest",
          position = {player.position.x + 1, player.position.y},
          force = player.force
        }
      end
      chest.insert(item)
    end
  end

  -- Convert items in given inventory, skipping blueprints and planners
  local function convert_inventory(inv)
    for i = 1, #inv do
      local stack = inv[i]
      if stack.valid_for_read and stack.quality ~= "legendary" and stack.count > 0 then
        -- Skip blueprint, blueprint book, upgrade planner, and deconstruction planner
        if stack.is_blueprint or stack.is_blueprint_book
           or stack.name == "upgrade-planner"
           or stack.name == "deconstruction-planner" then
          -- do nothing
        else
          -- Convert normal item to legendary
          local name = stack.name
          local count = stack.count
          local removed = inv.remove{name = name, count = count}
          if removed > 0 then
            local success = pcall(function()
              player.insert{name = name, count = removed, quality = "legendary"}
            end)
            if not success then
              safe_insert_or_store({name = name, count = removed})
            end
          end
        end
      end
    end
  end

  -- Apply conversion to main inventories
  convert_inventory(player.get_main_inventory())
  convert_inventory(player.get_inventory(defines.inventory.character_guns))
  convert_inventory(player.get_inventory(defines.inventory.character_ammo))

  -- Handle armor and equipment grid
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  local armor_stack = armor_inv[1]
  local equipment_buffer = {}

  if armor_stack.valid_for_read and armor_stack.grid then
    -- Remove and buffer equipment
    for _, eq in pairs(armor_stack.grid.equipment) do
      table.insert(equipment_buffer, {name = eq.name, size = (eq.shape.width or 1) * (eq.shape.height or 1)})
    end
    for _, eq in pairs(equipment_buffer) do
      pcall(function() armor_stack.grid.take{name = eq.name, count = 1} end)
    end
  end

  -- Convert armor itself
  if armor_stack.valid_for_read and armor_stack.quality ~= "legendary" then
    local name = armor_stack.name
    armor_inv.remove{name = name, count = 1}
    local success = pcall(function()
      player.insert{name = name, count = 1, quality = "legendary"}
    end)
    if not success then
      safe_insert_or_store({name = name, count = 1})
    end
  end

  -- Re-insert buffered equipment into new legendary armor
  local new_armor = armor_inv[1]
  if new_armor.valid_for_read and new_armor.grid then
    table.sort(equipment_buffer, function(a, b) return a.size > b.size end)
    for _, eq in pairs(equipment_buffer) do
      local ok = pcall(function()
        new_armor.grid.put{name = eq.name, quality = "legendary"}
      end)
      if not ok then
        safe_insert_or_store({name = eq.name, count = 1})
      end
    end
  end

  -- Restore original inventory slot bonus
  player.character_inventory_slots_bonus = original_bonus

  player.print({"facc.convert-inventory-msg"})
end

return M
