-- scripts/events/gui_events.lua
-- Handles GUI button clicks and routes them to feature modules
-- Uses preloaded requires to comply with Factorio limitations

local main_gui = require("scripts/gui/main_gui")
local console_gui = require("scripts/gui/console_gui")

-- PRELOAD ALL FEATURE MODULES
local features = {
  facc_toggle_editor = require("scripts/character/toggle_editor_mode"),
  facc_delete_ownerless = require("scripts/character/delete_ownerless_characters"),
  facc_convert_inventory = require("scripts/character/convert_inventory_to_legendary"),
  facc_build_blueprints = require("scripts/blueprint/build_ghost_blueprints"),
  facc_build_all_ghosts = require("scripts/blueprint/build_all_ghosts"),
  facc_remove_cliffs = require("scripts/map/remove_cliffs"),
  facc_remove_nests = require("scripts/map/remove_enemy_nests"),
  facc_reveal_map = require("scripts/map/reveal_map"),
  facc_hide_map = require("scripts/map/hide_map"),
  facc_remove_decon = require("scripts/map/remove_deconstruction_marks"),
  facc_remove_pollution = require("scripts/map/remove_pollution"),
  facc_convert_to_legendary = require("scripts/map/convert_constructions_to_legendary"),
  facc_repair_rebuild = require("scripts/misc/repair_and_rebuild"),
  facc_recharge_energy = require("scripts/misc/recharge_energy"),
  facc_ammo_turrets = require("scripts/misc/ammo_to_turrets"),
  facc_increase_resources = require("scripts/misc/increase_resources"),
  facc_unlock_recipes = require("scripts/unlocks/unlock_all_recipes"),
  facc_unlock_technologies = require("scripts/unlocks/unlock_all_technologies"),
  facc_unlock_achievements = require("scripts/unlocks/unlock_achievements")
}

-- Helper: extract slider value from GUI
local function get_slider_value(player, slider_name)
  local frame = player.gui.screen["facc_main_frame"]
  if not frame then return nil end

  for _, tab in pairs(frame.facc_tabbed_pane.children) do
    local slider = tab[slider_name]
    if slider and slider.valid then
      return math.floor(slider.slider_value)
    end
  end

  return nil
end

-- Helper: extract value from slider-textfield (fallback)
local function get_textbox_value(player, text_name)
  local frame = player.gui.screen["facc_main_frame"]
  if not frame then return nil end

  for _, tab in pairs(frame.facc_tabbed_pane.children) do
    local field = tab[text_name]
    if field and field.valid and tonumber(field.text) then
      return tonumber(field.text)
    end
  end

  return nil
end

-- GUI Click Dispatcher
script.on_event(defines.events.on_gui_click, function(event)
  local player = game.get_player(event.player_index)
  local element = event.element
  if not (player and element and element.valid) then return end

  local name = element.name

  -- Top GUI toggle
  if name == "facc_main_button" then
    main_gui.toggle_main_gui(player)

  -- Close menu
  elseif name == "facc_close_main_gui" then
    main_gui.toggle_main_gui(player)

  -- Console
  elseif name == "facc_console" then
    console_gui.toggle_console_gui(player)

  elseif name == "facc_console_exec" then
    console_gui.exec_console_command(player)

  elseif name == "facc_console_close" then
    console_gui.toggle_console_gui(player)

  -- Button: Match by name
  elseif features[name] then
    local handler = features[name]
    local radius = nil

    -- If feature uses slider
    if name == "facc_remove_cliffs" then
      radius = get_slider_value(player, "slider_remove_cliffs") or 50
    elseif name == "facc_remove_nests" then
      radius = get_slider_value(player, "slider_remove_nests") or 50
    elseif name == "facc_reveal_map" then
      radius = get_slider_value(player, "slider_reveal_map") or 150
    elseif name == "facc_convert_to_legendary" then
      radius = get_slider_value(player, "slider_convert_to_legendary") or 75
    end

    if radius then
      handler.run(player, radius)
    else
      handler.run(player)
    end
  end
end)

-- Safe update of textfield when a slider is moved
script.on_event(defines.events.on_gui_value_changed, function(event)
  local element = event.element
  if not (element and element.valid and element.type == "slider") then
    return
  end

  local player = game.get_player(event.player_index)
  if not player then return end

  local value_ok, value = pcall(function()
    return math.floor(element.slider_value)
  end)

  if not value_ok then return end

  local field = element.parent[element.name .. "_value"]
  if field and field.valid then
    field.text = tostring(value)
  end
end)
