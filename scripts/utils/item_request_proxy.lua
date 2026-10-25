-- Fulfill blueprint insert plans using the writable API shared by 2.0 and 2.1.
-- item_requests is a read-only summary. Respect planned inventories/slots and
-- retain only the outstanding counts so repeated passes cannot duplicate items.
local M = {}

local function quality_name(quality)
  if not quality then return "normal" end
  if type(quality) == "string" then return quality end
  return quality.name
end

local function fill_inventory_position(target, id, position, scratch)
  local inventory = target.get_inventory(position.inventory)
  local index = position.stack + 1 -- Blueprint positions are zero-based.
  if not inventory or index < 1 or index > #inventory then return 0 end
  local slot = inventory[index]
  if slot.valid_for_read and (slot.name ~= id.name or quality_name(slot.quality) ~= quality_name(id.quality)) then
    return 0
  end
  scratch.clear()
  local created = scratch.insert{name = id.name, quality = id.quality, count = position.count or 1}
  if created == 0 then return 0 end
  slot.transfer_stack(scratch[1])
  local remaining = scratch[1].valid_for_read and scratch[1].count or 0
  return created - remaining
end

local function fill_grid(target, id, count)
  if count <= 0 or not target.grid then return count end
  local item = prototypes.item[id.name]
  local equipment_prototype = item and item.place_as_equipment_result
  if not equipment_prototype then return count end
  local grid = target.grid
  for _, ghost in pairs(grid.equipment) do
    if count <= 0 then break end
    if ghost.valid and ghost.type == "equipment-ghost" and ghost.ghost_name == equipment_prototype.name
        and quality_name(ghost.quality) == quality_name(id.quality) then
      local placed = grid.put{name = equipment_prototype.name, quality = id.quality, position = ghost.position}
      if placed then count = count - 1 end
    end
  end
  return count
end

function M.fulfill(proxy)
  if not (proxy and proxy.valid and proxy.type == "item-request-proxy") then return true end
  local target = proxy.proxy_target
  if not (target and target.valid) then proxy.destroy(); return true end
  local scratch = game.create_inventory(1)
  local ok, remaining = pcall(function()
    local plans = {}
    for _, plan in ipairs(proxy.insert_plan) do
      local positions = {}
      for _, position in ipairs(plan.items.in_inventory or {}) do
        local count = (position.count or 1) - fill_inventory_position(target, plan.id, position, scratch)
        if count > 0 then
          positions[#positions + 1] = {inventory = position.inventory, stack = position.stack, count = count}
        end
      end
      local grid_count = fill_grid(target, plan.id, plan.items.grid_count or 0)
      if #positions > 0 or grid_count > 0 then
        plans[#plans + 1] = {id = plan.id, items = {in_inventory = positions, grid_count = grid_count}}
      end
    end
    return plans
  end)
  scratch.destroy()
  if not ok then error(remaining) end
  if not proxy.valid then return true end
  if #remaining == 0 then
    -- A removal-only proxy still has work for the game's construction robots.
    if #proxy.removal_plan > 0 then proxy.insert_plan = {}; return false end
    proxy.destroy()
    return true
  end
  proxy.insert_plan = remaining
  return false
end

return M
