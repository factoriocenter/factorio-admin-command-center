-- control.lua
-- Factorio Admin Command Center (FACC) - Modular Version
-- Author: louanbastos
-- This file acts as the main entry point of the mod,
-- loading modules, registering events and exposing the global permission check.

-- List of required modules (main orchestration)
local modules = {
  "scripts/init",               -- Adds GUI button and shortcut
  "scripts/gui/main_gui",      -- Main interface (tabbed pane layout)
  "scripts/gui/console_gui",   -- Console interface (Lua executor)
  "scripts/events/gui_events", -- Handles GUI click events
  "scripts/events/player_events" -- Handles player join/create events
}

-- Dynamically require each module
for _, path in pairs(modules) do
  require(path)
end

-- Permission checker utility
-- Grants access to all players in singleplayer,
-- and only admin players in multiplayer sessions
function is_allowed(player)
  return not game.is_multiplayer() or player.admin
end
