-- control.lua
-- Main entry point for the Factorio Admin Command Center (FACC) mod.

--------------------------------------------------------------------------------
-- Shared permission checker
--------------------------------------------------------------------------------
local permissions = require("scripts.utils.permissions")
_G.is_allowed = permissions.is_allowed

--------------------------------------------------------------------------------
-- Remove legacy UI buttons on init/updates
--------------------------------------------------------------------------------
local function remove_old_button()
  for _, player in pairs(game.players) do
    for _, name in ipairs({ "facc_main_button", "factorio_admin_command_center_button" }) do
      local btn = player.gui.top[name]
      if btn and btn.valid then btn.destroy() end
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
-- On first load
--------------------------------------------------------------------------------
script.on_init(function()
  remove_old_button()
  update_legendary_shortcut_availability()
end)

--------------------------------------------------------------------------------
-- Whenever mods change (e.g. Quality toggled) or mod is updated
--------------------------------------------------------------------------------
script.on_configuration_changed(function(event)
  remove_old_button()
  update_legendary_shortcut_availability()
end)

--------------------------------------------------------------------------------
-- Re-check whenever a player joins (covers save-load and multiplayer joins)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_player_joined_game, update_legendary_shortcut_availability)

--------------------------------------------------------------------------------
-- Load core modules
--------------------------------------------------------------------------------
for _, path in ipairs({
  "scripts/init",
  "scripts/gui/main_gui",
  "scripts/automations/clean_pollution",
  "scripts/automations/instant_research",
  "scripts/gui/console_gui",
  "scripts/events/gui_events",
  "scripts/legendary_upgrader"
}) do
  require(path)
end

local main_gui    = require("scripts/gui/main_gui")
local console_gui = require("scripts/gui/console_gui")

--------------------------------------------------------------------------------
-- Toggle admin GUI with Ctrl + .
--------------------------------------------------------------------------------
script.on_event("facc_toggle_gui", function(e)
  local player = game.get_player(e.player_index)
  if player then main_gui.toggle_main_gui(player) end
end)

--------------------------------------------------------------------------------
-- Handle toolbar shortcuts
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- Execute Lua console command with Ctrl + Enter
--------------------------------------------------------------------------------
script.on_event("facc_console_exec_input", function(e)
  local player = game.get_player(e.player_index)
  if player and player.gui.screen.facc_console_frame then
    console_gui.exec_console_command(player)
  end
end)
