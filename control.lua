-- control.lua
-- Factorio Admin Command Center (FACC) - Modular Version
-- Author: louanbastos
-- This file acts as the main entry point of the mod:
--   • defines permission checks
--   • loads all feature modules
--   • hooks the CTRL+. shortcut for the main GUI

-- Permission checker utility
-- Grants access to all players in singleplayer,
-- and only admin players in multiplayer sessions
function is_allowed(player)
  return not game.is_multiplayer() or player.admin
end

-- List of required modules (main orchestration)
local modules = {
  "scripts/init",               -- Adds GUI button and shortcut
  "scripts/gui/main_gui",       -- Main tabbed interface
  "scripts/gui/console_gui",    -- Lua console GUI
  "scripts/events/gui_events",  -- Routes GUI button clicks
  "scripts/events/player_events",-- Adds the top‐bar button
  "scripts/legendary_upgrader"  -- Legendary Upgrader tool & shortcut
}

-- Dynamically require each module
for _, path in pairs(modules) do
  require(path)
end

-- Reference to main GUI module for toggling via custom input
local main_gui = require("scripts/gui/main_gui")

-- Register custom-input event (CTRL + .) to toggle the admin GUI
script.on_event("facc_toggle_gui", function(event)
  local player = game.get_player(event.player_index)
  if player then
    main_gui.toggle_main_gui(player)
  end
end)
