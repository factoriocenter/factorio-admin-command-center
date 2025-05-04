-- control.lua
-- Main entry point for the mod. Handles both GUI toggle and Legendary Upgrader toolbar shortcuts.

-- Checks if the player is allowed to use admin features (singleplayer or admin in multiplayer)
function is_allowed(player)
  return not game.is_multiplayer() or player.admin
end

-- Load all core modules; legendary_upgrader.lua no longer registers its own shortcut handler
local modules = {
  "scripts/init",
  "scripts/gui/main_gui",
  "scripts/gui/console_gui",
  "scripts/events/gui_events",
  "scripts/events/player_events",
  "scripts/legendary_upgrader"
}
for _, path in pairs(modules) do
  require(path)
end

-- Reference to the main GUI module
local main_gui = require("scripts/gui/main_gui")

-- Handle Ctrl + . custom input to toggle the admin GUI
script.on_event("facc_toggle_gui", function(event)
  local player = game.get_player(event.player_index)
  if player then
    main_gui.toggle_main_gui(player)
  end
end)

-- Handle toolbar shortcuts for GUI toggle and Legendary Upgrader
script.on_event(defines.events.on_lua_shortcut, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  local name = event.prototype_name

  if name == "facc_toggle_gui_shortcut" then
    -- Toggle the admin GUI
    main_gui.toggle_main_gui(player)

  elseif name == "facc_give_legendary_upgrader" then
    -- Equip the Legendary Upgrader tool if permitted
    if is_allowed(player) then
      player.clear_cursor()
      player.cursor_stack.set_stack({ name = "facc_legendary_upgrader" })
      player.print({ "facc.legendary-upgrader-equipped" })
    end
  end
end)
