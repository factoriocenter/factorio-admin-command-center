-- scripts/events/player_events.lua
-- Handles events related to player lifecycle such as creation, join, and respawn.
-- Ensures UI button is added when appropriate.

local function add_main_button(player)
  if is_allowed(player) and not player.gui.top["facc_main_button"] then
    player.gui.top.add{
      type = "button",
      name = "facc_main_button",
      caption = {"facc.button-caption"},
      tooltip = {"facc.tooltip-main"}
    }
  end
end

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player then add_main_button(player) end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  if player then add_main_button(player) end
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)
  if player then add_main_button(player) end
end)
