-- scripts/blueprints/convert_constructions_to_legendary.lua
-- This module upgrades all eligible constructions in an area around the player
-- to legendary quality using a temporary upgrade planner and ghost revival.
-- Enhanced: temporarily research construction robotics if not researched.

local M = {}

function M.run(player, radius)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force = player.force
  local position = player.position
  local area = {
    {position.x - radius, position.y - radius},
    {position.x + radius, position.y + radius}
  }

  -- Ensure construction robotics technology is available for ghost placement
  local tech = force.technologies["construction-robotics"]
  local had_tech = tech and tech.researched
  if tech and not had_tech then
    tech.researched = true
  end

  -- Step 1: Destroy valid entities to leave ghosts (with correct rotation)
  for _, entity in pairs(surface.find_entities_filtered{area = area, force = force}) do
    if entity.valid and entity.minable and entity.prototype.items_to_place_this then
      entity.die()
    end
  end

  -- Step 2: Setup temporary upgrade planner
  local success, inventory = pcall(function() return game.create_inventory(1) end)
  if not success then
    player.print("Error: could not create temporary upgrade planner inventory.")
    return
  end

  inventory[1].set_stack{name = "upgrade-planner"}
  local planner = inventory[1]
  local mapped = {}

  -- Maps ghost entities to their legendary version
  for _, ghost in pairs(surface.find_entities_filtered{area = area, name = "entity-ghost", force = force}) do
    if ghost.ghost_prototype and ghost.ghost_prototype.items_to_place_this then
      local name = ghost.ghost_name
      if not mapped[name] then
        local idx = table_size(mapped) + 1
        local ok = pcall(function()
          planner.set_mapper(idx, "from", {type = "entity", name = name})
          planner.set_mapper(idx, "to", {type = "entity", name = name, quality = "legendary"})
        end)
        if ok then
          mapped[name] = true
        end
      end
    end
  end

  -- Apply the planner upgrade to the area
  surface.upgrade_area{
    area = area,
    force = force,
    player = player,
    skip_fog_of_war = true,
    item = planner
  }

  inventory.destroy()

  -- Step 3: Revive legendary ghosts
  for _, ghost in pairs(surface.find_entities_filtered{area = area, name = "entity-ghost", force = force}) do
    if ghost.valid then
      ghost.revive()
    end
  end

  -- Revert construction robotics technology if it was not researched before
  if tech and not had_tech then
    tech.researched = false
  end

  player.print({"facc.convert-to-legendary-msg"})
end

return M
