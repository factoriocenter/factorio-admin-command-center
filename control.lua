-- control.lua
-- Main entry point for the Factorio Admin Command Center (FACC) mod.
-- Responsibilities:
--   * Remove legacy UI buttons on init and updates
--   * Load core script modules
--   * Handle admin GUI toggling (Ctrl + . and toolbar shortcut)
--   * Handle Legendary Upgrader provisioning via shortcut
--   * Handle Lua Console execution via custom input (Ctrl + Enter)

--------------------------------------------------------------------------------
-- Permission check: allow admin features only in single-player or if player is admin
--------------------------------------------------------------------------------
local function is_allowed(player)
  return not game.is_multiplayer() or player.admin
end

--------------------------------------------------------------------------------
-- Remove old top-left toggle buttons on init and after mod updates
--------------------------------------------------------------------------------
local function remove_old_button()
  for _, p in pairs(game.players) do
    for _, name in ipairs({ "facc_main_button", "factorio_admin_command_center_button" }) do
      local btn = p.gui.top[name]
      if btn and btn.valid then
        btn.destroy()
      end
    end
  end
end

-- On first load: remove legacy buttons from existing saves
script.on_init(remove_old_button)

-- On mod configuration changed (e.g. update): remove legacy buttons again
script.on_configuration_changed(function(event)
  local changes = event.mod_changes and event.mod_changes["factorio-admin-command-center"]
  if changes and changes.new_version then
    remove_old_button()
  end
end)

--------------------------------------------------------------------------------
-- Load all core modules in order: init, GUI, automations, console, events, upgrader
--------------------------------------------------------------------------------
local modules = {
  "scripts/init",
  "scripts/gui/main_gui",
  "scripts/automations/clean_pollution",
  "scripts/automations/instant_research",
  "scripts/gui/console_gui",
  "scripts/events/gui_events",
  "scripts/legendary_upgrader"
}
for _, path in pairs(modules) do
  require(path)
end

-- Reference to the main GUI module for toggling the Admin Command Center
local main_gui = require("scripts/gui/main_gui")
-- Reference to the console GUI module for executing commands via shortcut
local console_gui = require("scripts/gui/console_gui")

--------------------------------------------------------------------------------
-- Handle custom input "facc_toggle_gui" (Ctrl + .) to toggle the admin GUI
--------------------------------------------------------------------------------
script.on_event("facc_toggle_gui", function(event)
  local player = game.get_player(event.player_index)
  if player then
    main_gui.toggle_main_gui(player)
  end
end)

--------------------------------------------------------------------------------
-- Handle toolbar shortcut events:
--   * "facc_toggle_gui_shortcut" → toggle admin GUI
--   * "facc_give_legendary_upgrader" → give the Legendary Upgrader tool
--------------------------------------------------------------------------------
script.on_event(defines.events.on_lua_shortcut, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  local name = event.prototype_name
  if name == "facc_toggle_gui_shortcut" then
    -- Toggle the main GUI
    main_gui.toggle_main_gui(player)

  elseif name == "facc_give_legendary_upgrader" then
    -- Give Legendary Upgrader if allowed
    if is_allowed(player) then
      player.clear_cursor()
      player.cursor_stack.set_stack({ name = "facc_legendary_upgrader" })
      player.print({ "facc.legendary-upgrader-equipped" })
    end
  end
end)

--------------------------------------------------------------------------------
-- Handle custom input "facc_console_exec_input" (Ctrl + Enter) to run console
--------------------------------------------------------------------------------
script.on_event("facc_console_exec_input", function(event)
  local player = game.get_player(event.player_index)
  -- Only run if the console GUI frame is open
  if player and player.gui.screen.facc_console_frame then
    console_gui.exec_console_command(player)
  end
end)
