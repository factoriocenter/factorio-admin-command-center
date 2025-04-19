-- scripts/character/convert_inventory_to_legendary.lua
-- This module converts all items in the player's inventory, weapons, ammo,
-- and armor (including equipment) into their legendary quality versions.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Temporarily increase inventory capacity to prevent overflow
  local original_bonus = player.character_inventory_slots_bonus or 0
  if player.character then
    player.character_inventory_slots_bonus = original_bonus + 1000
  end

  -- Helper to insert into inventory or nearby chest
  local function safe_insert_or_store(item)
    if player.can_insert(item) then
      player.insert(item)
      return true
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
      return false
    end
  end

  -- Convert an inventory slot to legendary
  local function convert_inventory(inv)
    for i = 1, #inv do
      local stack = inv[i]
      if stack.valid_for_read and stack.quality ~= "legendary" and stack.count > 0 then
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

  -- Convert all relevant inventories
  convert_inventory(player.get_main_inventory())
  convert_inventory(player.get_inventory(defines.inventory.character_guns))
  convert_inventory(player.get_inventory(defines.inventory.character_ammo))

  -- Handle armor and equipment grid
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  local armor_stack = armor_inv[1]
  local equipment_buffer = {}

  if armor_stack.valid_for_read and armor_stack.grid then
    for _, eq in pairs(armor_stack.grid.equipment) do
      table.insert(equipment_buffer, {
        name = eq.name,
        size = (eq.shape.width or 1) * (eq.shape.height or 1)
      })
    end
    for _, eq in pairs(equipment_buffer) do
      pcall(function()
        armor_stack.grid.take{name = eq.name, count = 1}
      end)
    end
  end

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

  -- Restore equipment into new legendary armor
  local new_armor = armor_inv[1]
  if new_armor.valid_for_read and new_armor.grid then
    table.sort(equipment_buffer, function(a, b) return a.size > b.size end)
    for _, eq in pairs(equipment_buffer) do
      local success = pcall(function()
        new_armor.grid.put{name = eq.name, quality = "legendary"}
      end)
      if not success then
        safe_insert_or_store({name = eq.name, count = 1})
      end
    end
  end

  -- Final reinsert in case of forced override
  local final_armor = armor_inv[1]
  if final_armor.valid_for_read then
    local armor_name = final_armor.name
    local armor_quality = final_armor.quality
    armor_inv.remove{name = armor_name, count = 1}
    player.insert{name = armor_name, count = 1, quality = armor_quality}
  end

  -- Restore inventory bonus
  if player.character then
    player.character_inventory_slots_bonus = original_bonus
  end

  player.print({"facc.convert-inventory-msg"})
end

return M
