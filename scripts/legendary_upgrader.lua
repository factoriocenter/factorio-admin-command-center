-- scripts/legendary_upgrader.lua
-- Legendary Upgrader tool: select an area and convert every entity in that area
-- to "legendary" quality, using the vanilla upgrade-planner.

local TOOL_NAME     = "facc_legendary_upgrader"
local SHORTCUT_NAME = "facc_give_legendary_upgrader"
local QUALITY       = "legendary"  -- hard-coded legendary

--------------------------------------------------------------------------------
-- Simple permission check: singleplayer or admin only
--------------------------------------------------------------------------------
local function is_allowed(player)
  return player and (not game.is_multiplayer() or player.admin)
end

--------------------------------------------------------------------------------
-- Toolbar shortcut: equip the upgrader tool
--------------------------------------------------------------------------------
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= SHORTCUT_NAME then return end
  local player = game.get_player(event.player_index)
  if not is_allowed(player) then return end

  player.clear_cursor()
  player.cursor_stack.set_stack({ name = TOOL_NAME })
  player.print({ "facc.legendary-upgrader-equipped" })
end)

--------------------------------------------------------------------------------
-- Main upgrader: when user drag-selects with our tool
--------------------------------------------------------------------------------
script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item ~= TOOL_NAME then return end
  local player = game.get_player(event.player_index)
  if not is_allowed(player) then return end

  local surface = player.surface
  local force   = player.force

  -- create a 1-slot temporary inventory
  local ok, inventory = pcall(game.create_inventory, 1)
  if not ok then
    player.print({ "facc.legendary-upgrader-error" })
    return
  end

  -- put the vanilla upgrade-planner into that slot
  local planner = inventory[1]
  planner.set_stack({ name = "upgrade-planner" })

  -- build a unique list of prototype names (real + ghost)
  local seen = {}
  local idx  = 0
  for _, ent in ipairs(event.entities) do
    if ent.valid then
      local proto = (ent.type == "entity-ghost") and ent.ghost_name or ent.name
      if not seen[proto] then
        seen[proto] = true
        idx = idx + 1
        -- map "from" = this prototype
        planner.set_mapper(idx, "from", { type = "entity", name = proto })
        -- map "to"   = same prototype but legendary
        planner.set_mapper(idx, "to",   { type = "entity", name = proto, quality = QUALITY })
      end
    end
  end

  -- apply the upgrade-planner over the area
  surface.upgrade_area{
    area            = event.area,
    force           = force,
    player          = player,
    skip_fog_of_war = true,
    item            = planner,
  }

  -- destroy temp inventory and inform the player
  inventory.destroy()
  player.print({ "facc.legendary-upgrader-success" })
end)
