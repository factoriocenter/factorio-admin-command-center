-- scripts/utils/mod_compat.lua
-- Runtime helpers to improve compatibility with modded environments.

local M = {}

function M.is_mod_active(mod_name)
  return script
    and script.active_mods
    and type(mod_name) == "string"
    and script.active_mods[mod_name] ~= nil
end

function M.prototype_exists(collection_name, prototype_name)
  if type(collection_name) ~= "string" or type(prototype_name) ~= "string" then
    return false
  end
  if not game then
    return false
  end
  local collection = game[collection_name]
  return type(collection) == "table" and collection[prototype_name] ~= nil
end

function M.find_first_existing(collection_name, candidates)
  if type(candidates) ~= "table" then
    return nil
  end
  for _, name in ipairs(candidates) do
    if M.prototype_exists(collection_name, name) then
      return name
    end
  end
  return nil
end

function M.safe_player_insert(player, stack)
  if not (player and player.valid and type(stack) == "table" and type(stack.name) == "string") then
    return 0
  end
  if not M.prototype_exists("item_prototypes", stack.name) then
    return 0
  end

  local inserted = 0
  local ok = pcall(function()
    inserted = player.insert(stack)
  end)
  if ok then
    return inserted
  end

  if stack.quality ~= nil then
    local fallback = { name = stack.name, count = stack.count or 1 }
    local ok_fallback = pcall(function()
      inserted = player.insert(fallback)
    end)
    if ok_fallback then
      return inserted
    end
  end

  return 0
end

function M.safe_set_stack(item_stack, stack)
  if not (item_stack and item_stack.valid and type(stack) == "table" and type(stack.name) == "string") then
    return false
  end
  if not M.prototype_exists("item_prototypes", stack.name) then
    return false
  end

  local ok = pcall(function()
    item_stack.set_stack(stack)
  end)
  if ok then
    return true
  end

  if stack.quality ~= nil then
    ok = pcall(function()
      item_stack.set_stack({ name = stack.name, count = stack.count or 1 })
    end)
    if ok then
      return true
    end
  end

  return false
end

function M.safe_grid_put(grid, equipment)
  if not (grid and grid.valid and type(equipment) == "table" and type(equipment.name) == "string") then
    return false
  end
  if not M.prototype_exists("equipment_prototypes", equipment.name) then
    return false
  end

  local ok = pcall(function()
    grid.put(equipment)
  end)
  if ok then
    return true
  end

  if equipment.quality ~= nil then
    ok = pcall(function()
      grid.put({ name = equipment.name, position = equipment.position })
    end)
    if ok then
      return true
    end
  end

  return false
end

return M
