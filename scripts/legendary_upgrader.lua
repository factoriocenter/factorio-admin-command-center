-- scripts/legendary_upgrader.lua
-- Legendary Upgrader tool: handles area selection to upgrade entities to legendary quality.

local TOOL_NAME = "facc_legendary_upgrader"
local QUALITY   = "legendary"  -- hard-coded legendary quality

-- Main upgrader: triggered when player selects an area with our tool
script.on_event(defines.events.on_player_selected_area, function(event)
  -- only proceed if this is our Legendary Upgrader
  if event.item ~= TOOL_NAME then return end

  local player = game.get_player(event.player_index)
  if not is_allowed(player) then return end

  local surface = player.surface
  local force   = player.force

  -- create a temporary 1-slot inventory and put in a vanilla upgrade-planner
  local ok, inventory = pcall(game.create_inventory, 1)
  if not ok then
    player.print({ "facc.legendary-upgrader-error" })
    return
  end

  local planner = inventory[1]
  planner.set_stack({ name = "upgrade-planner" })

  -- build a unique mapper list (from→to) for each prototype
  local seen = {}
  local idx  = 0
  for _, ent in ipairs(event.entities) do
    if ent.valid then
      local proto = (ent.type == "entity-ghost") and ent.ghost_name or ent.name
      if not seen[proto] then
        seen[proto] = true
        idx = idx + 1
        planner.set_mapper(idx, "from", { type = "entity", name = proto })
        planner.set_mapper(idx, "to",   { type = "entity", name = proto, quality = QUALITY })
      end
    end
  end

  -- apply the upgrade over the selected area
  surface.upgrade_area{
    area            = event.area,
    force           = force,
    player          = player,
    skip_fog_of_war = true,
    item            = planner,
  }

  -- destroy temp inventory and notify player
  inventory.destroy()
  player.print({ "facc.legendary-upgrader-success" })
end)
