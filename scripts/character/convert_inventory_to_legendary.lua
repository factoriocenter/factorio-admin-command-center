-- scripts/character/convert_inventory_to_legendary.lua
-- Converts all items in the player's inventory, weapons, ammo, armor, and equipment to legendary quality
-- Ignores blueprints, blueprint books, and both vanilla planners (upgrade and deconstruction)

local M = {}
local compat = require("scripts/utils/mod_compat")

local function is_legendary_quality(quality)
  if quality == nil then
    return false
  end
  if type(quality) == "string" then
    return quality == "legendary"
  end
  return quality.name == "legendary"
end

local function stack_is_legendary(stack)
  if not (stack and stack.valid_for_read) then
    return false
  end
  return is_legendary_quality(stack.quality)
end

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
    if compat.safe_player_insert(player, item) > 0 then
      return
    end

    local chest_name = compat.find_first_existing("entity_prototypes", {
      "steel-chest",
      "iron-chest",
      "wooden-chest"
    })
    if not chest_name then
      return
    end

    local chest = player.surface.find_entity(chest_name, player.position)
    if not chest then
      chest = player.surface.create_entity{
        name = chest_name,
        position = {player.position.x + 1, player.position.y},
        force = player.force
      }
    end
    if chest and chest.valid then
      chest.insert(item)
    end
  end

  local function convert_stack_to_legendary(stack)
    if not (stack and stack.valid_for_read) then
      return false
    end
    if stack_is_legendary(stack) then
      return true
    end
    local ok, changed = pcall(function()
      return stack.set_stack({ name = stack.name, count = stack.count, quality = "legendary" })
    end)
    return ok and changed == true
  end

  local function convert_armor_stack_preserve_grid(stack)
    if not (stack and stack.valid_for_read) then
      return true
    end
    if stack_is_legendary(stack) then
      return true
    end

    local equipment_snapshot = {}
    if stack.grid then
      for _, eq in pairs(stack.grid.equipment) do
        equipment_snapshot[#equipment_snapshot + 1] = {
          name = eq.name,
          position = { x = eq.position.x, y = eq.position.y },
          size = (eq.shape.width or 1) * (eq.shape.height or 1)
        }
      end
    end

    local converted = convert_stack_to_legendary(stack)
    if not converted then
      return false
    end

    if #equipment_snapshot == 0 then
      return true
    end

    local grid = stack.grid
    if not grid then
      local ok, created_grid = pcall(function()
        return stack.create_grid()
      end)
      if ok then
        grid = created_grid
      end
    end

    if not grid then
      for _, eq in pairs(equipment_snapshot) do
        safe_insert_or_store({ name = eq.name, count = 1, quality = "legendary" })
      end
      return true
    end

    table.sort(equipment_snapshot, function(a, b) return a.size > b.size end)
    for _, eq in pairs(equipment_snapshot) do
      local placed = compat.safe_grid_put(grid, {
        name = eq.name,
        quality = "legendary",
        position = eq.position
      })
      if not placed then
        placed = compat.safe_grid_put(grid, {
          name = eq.name,
          position = eq.position
        })
      end
      if not placed then
        safe_insert_or_store({ name = eq.name, count = 1, quality = "legendary" })
      end
    end

    return true
  end

  -- Convert items in given inventory, skipping blueprints and planners
  local function convert_inventory(inv)
    if not inv then
      return
    end
    for i = 1, #inv do
      local stack = inv[i]
      if stack.valid_for_read and not stack_is_legendary(stack) and stack.count > 0 then
        -- Skip blueprint, blueprint book, upgrade planner, and deconstruction planner
        if stack.is_blueprint or stack.is_blueprint_book
           or stack.name == "upgrade-planner"
           or stack.name == "deconstruction-planner" then
          -- do nothing
        else
          -- Preserve equipment grids for armor stacks in normal inventories.
          if stack.grid and stack.count == 1 then
            local ok = convert_armor_stack_preserve_grid(stack)
            if not ok then
              -- Do not fallback remove/insert for armor-with-grid, to avoid
              -- item-data loss or accidental duplication. Keep original stack.
              player.print({ "facc.runtime-compat-error", "facc_convert_inventory_armor_stack" })
            end
          else
            local ok = convert_stack_to_legendary(stack)
            if not ok then
              -- Fallback conversion path for stack types that reject set_stack.
              local name = stack.name
              local count = stack.count
              local removed = inv.remove({ name = name, count = count })
              if removed > 0 then
                local inserted = compat.safe_player_insert(player, { name = name, count = removed, quality = "legendary" })
                if inserted < removed then
                  safe_insert_or_store({ name = name, count = (removed - inserted), quality = "legendary" })
                end
              end
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
  if not armor_inv then
    player.character_inventory_slots_bonus = original_bonus
    player.print({"facc.convert-inventory-msg"})
    return
  end

  -- Convert equipped armor (and preserve its grid) if needed.
  local armor_stack = armor_inv[1]
  if armor_stack.valid_for_read and not stack_is_legendary(armor_stack) then
    local ok = convert_armor_stack_preserve_grid(armor_stack)
    if not ok then
      -- Last-resort fallback: keep the original armor untouched instead of risking duplication/loss.
      player.print({ "facc.runtime-compat-error", "facc_convert_inventory_armor" })
    end
  end

  -- Restore original inventory slot bonus
  player.character_inventory_slots_bonus = original_bonus

  player.print({"facc.convert-inventory-msg"})
end

return M
