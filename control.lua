-- control.lua
-- Main entry point for the Factorio Admin Command Center (FACC) mod.

--------------------------------------------------------------------------------
-- Shared permission checker
--------------------------------------------------------------------------------
local permissions = require("scripts/utils/permissions")
_G.is_allowed = permissions.is_allowed

--------------------------------------------------------------------------------
-- Helpers for resource regeneration
--------------------------------------------------------------------------------
-- Restore finite resources when infinite-resources is disabled
local regenerate_finite   = require("scripts/planets/regenerate_resources")
-- Top up infinite resources to exactly N× prototype normal amount
local regenerate_infinite = require("scripts/startup-settings/regenerate_to_infinite_resources")

--------------------------------------------------------------------------------
-- Utility: top up infinite resources in a given area (used on chunk generation)
--------------------------------------------------------------------------------
local function top_up_area(surface, area)
  -- Read multiplier setting at runtime (e.g., "5x" -> 5)
  local mult_str   = settings.startup["facc-infinite-resources-multiplier"].value or "1x"
  local multiplier = tonumber(mult_str:match("^(%d+)x$")) or 1

  for _, resource in pairs(surface.find_entities_filtered{ area = area, type = "resource" }) do
    if resource.prototype.infinite_resource then
      -- set both initial and current amounts according to multiplier
      local full_amount = resource.prototype.normal_resource_amount * multiplier
      resource.initial_amount = full_amount
      resource.amount         = full_amount
    end
  end
end

--------------------------------------------------------------------------------
-- Remove legacy UI buttons on init/updates
--------------------------------------------------------------------------------
local function remove_old_button()
  for _, player in pairs(game.players) do
    for _, name in ipairs({ "facc_main_button", "factorio_admin_command_center_button" }) do
      local btn = player.gui.top[name]
      if btn and btn.valid then
        btn.destroy()
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Hide or show the Legendary Upgrader shortcut based on Quality mod presence
--------------------------------------------------------------------------------
local function update_legendary_shortcut_availability()
  local quality_active = script.active_mods["quality"] ~= nil
  for _, player in pairs(game.players) do
    player.set_shortcut_available("facc_give_legendary_upgrader", quality_active)
  end
end

--------------------------------------------------------------------------------
-- On first load: remove old buttons and update shortcuts
--------------------------------------------------------------------------------
script.on_init(function()
  remove_old_button()
  update_legendary_shortcut_availability()
end)

--------------------------------------------------------------------------------
-- When configuration changes (mod update or startup setting change):
-- 1) remove old buttons
-- 2) update legendary upgrader shortcut
-- 3) automatically regenerate resources if user did NOT disable it
--------------------------------------------------------------------------------
script.on_configuration_changed(function(event)
  remove_old_button()
  update_legendary_shortcut_availability()

  -- Skip auto-regeneration if the user has activated the new setting
  if not settings.startup["facc-disable-auto-resource-regeneration"].value then
    -- If infinite-resources was just disabled, restore finite resources on all surfaces
    if not settings.startup["facc-infinite-resources"].value then
      for _, surface in pairs(game.surfaces) do
        -- dummy context to satisfy regenerate_finite.run
        local ctx = {
          surface = surface,
          admin   = true,
          print   = function() end
        }
        regenerate_finite.run(ctx)
      end
    end

    -- If infinite-resources is enabled, top up every existing surface to N× once
    if settings.startup["facc-infinite-resources"].value then
      for _, surface in pairs(game.surfaces) do
        regenerate_infinite.run_on_surface(surface)
      end
    end
  end
end)

--------------------------------------------------------------------------------
-- Whenever a player joins (covers save-load and multiplayer joins)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_player_joined_game, update_legendary_shortcut_availability)

--------------------------------------------------------------------------------
-- When a new chunk is generated: enforce infinite-resource top-up if setting is on
--------------------------------------------------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)
  if settings.startup["facc-infinite-resources"].value then
    top_up_area(event.surface, event.area)
  end
end)

--------------------------------------------------------------------------------
-- When a new surface is created: enforce infinite-resource top-up if setting is on
--------------------------------------------------------------------------------
script.on_event(defines.events.on_surface_created, function(event)
  if settings.startup["facc-infinite-resources"].value then
    local surf = game.surfaces[event.surface_index]
    regenerate_infinite.run_on_surface(surf)
  end
end)

--------------------------------------------------------------------------------
-- Load core modules
--------------------------------------------------------------------------------
for _, path in ipairs({
  "scripts/init",
  "scripts/gui/main_gui",
  "scripts/environment/clean_pollution",
  "scripts/environment/remove_ground_items",
  "scripts/cheats/instant_research",
  "scripts/gui/console_gui",
  "scripts/events/gui_events",
  "scripts/legendary-upgrader/legendary_upgrader"
}) do
  require(path)
end

--------------------------------------------------------------------------------
-- Shortcut handlers (Ctrl+., Ctrl+Enter, toolbar buttons)
--------------------------------------------------------------------------------
local main_gui    = require("scripts/gui/main_gui")
local console_gui = require("scripts/gui/console_gui")

-- Toggle admin GUI with Ctrl+.
script.on_event("facc_toggle_gui", function(e)
  local player = game.get_player(e.player_index)
  if player then
    main_gui.toggle_main_gui(player)
  end
end)

-- Handle toolbar shortcuts
script.on_event(defines.events.on_lua_shortcut, function(e)
  local player = game.get_player(e.player_index)
  if not player then return end

  if e.prototype_name == "facc_toggle_gui_shortcut" then
    main_gui.toggle_main_gui(player)

  elseif e.prototype_name == "facc_give_legendary_upgrader" then
    if is_allowed(player) then
      player.clear_cursor()
      player.cursor_stack.set_stack({ name = "facc_legendary_upgrader" })
      player.print({ "facc.legendary-upgrader-equipped" })
    end
  end
end)

-- Execute Lua console command with Ctrl+Enter
script.on_event("facc_console_exec_input", function(e)
  local player = game.get_player(e.player_index)
  if player and player.gui.screen.facc_console_frame then
    console_gui.exec_console_command(player)
  end
end)
