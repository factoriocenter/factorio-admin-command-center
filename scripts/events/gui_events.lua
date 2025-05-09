-- scripts/events/gui_events.lua
-- Handles GUI clicks, slider changes, switch toggles, and automation loops

local main_gui                = require("scripts/gui/main_gui")
local console_gui             = require("scripts/gui/console_gui")
local clean_pollution         = require("scripts/automations/clean_pollution")
local instant_research        = require("scripts/automations/instant_research")
local cheat_mode              = require("scripts/automations/cheat_mode")
local always_day              = require("scripts/automations/always_day")
local disable_pollution       = require("scripts/automations/disable_pollution")
local disable_friendly_fire   = require("scripts/automations/disable_friendly_fire")
local peaceful_mode           = require("scripts/automations/peaceful_mode")
local enemy_expansion         = require("scripts/automations/enemy_expansion")
local indestructible_builds   = require("scripts/automations/indestructible_builds")

-- Add our new command
-- (não precisa de local extra, pois vamos usar dentro da tabela abaixo)
--------------------------------------------------------------------------------

-- Persistence initializer from main_gui
local ensure_persistent_state = main_gui.ensure_persistent_state

-- Preload all feature modules (buttons in other tabs)
local features = {
  facc_toggle_editor          = require("scripts/character/toggle_editor_mode"),
  facc_delete_ownerless       = require("scripts/character/delete_ownerless_characters"),
  facc_convert_inventory      = require("scripts/character/convert_inventory_to_legendary"),
  facc_create_legendary_armor = require("scripts/character/create_legendary_armor"),
  facc_build_all_ghosts       = require("scripts/blueprint/build_all_ghosts"),
  facc_upgrade_blueprints     = require("scripts/blueprint/upgrade_blueprints_to_legendary"),
  facc_remove_cliffs          = require("scripts/map/remove_cliffs"),
  facc_remove_nests           = require("scripts/map/remove_enemy_nests"),
  facc_reveal_map             = require("scripts/map/reveal_map"),
  facc_hide_map               = require("scripts/map/hide_map"),
  facc_remove_decon           = require("scripts/map/remove_deconstruction_marks"),
  facc_remove_pollution       = require("scripts/map/remove_pollution"),
  facc_convert_to_legendary   = require("scripts/map/convert_constructions_to_legendary"),
  facc_repair_rebuild         = require("scripts/misc/repair_and_rebuild"),
  facc_recharge_energy        = require("scripts/misc/recharge_energy"),
  facc_ammo_turrets           = require("scripts/misc/ammo_to_turrets"),
  facc_increase_resources     = require("scripts/misc/increase_resources"),
  facc_unlock_recipes         = require("scripts/unlocks/unlock_all_recipes"),
  facc_unlock_technologies    = require("scripts/unlocks/unlock_all_technologies"),
  facc_unlock_achievements    = require("scripts/unlocks/unlock_achievements")
}

--------------------------------------------------------------------------------
-- GUI Click Dispatcher (tabs, buttons, console)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
  local player, element = game.get_player(event.player_index), event.element
  if not (player and element and element.valid) then return end
  local name = element.name

  -- Toggle main GUI
  if name == "facc_main_button" or name == "facc_close_main_gui" then
    main_gui.toggle_main_gui(player)
    return
  end

  -- Console controls
  if name == "facc_console"       then console_gui.toggle_console_gui(player); return end
  if name == "facc_console_exec"  then console_gui.exec_console_command(player);  return end
  if name == "facc_console_close" then console_gui.toggle_console_gui(player); return end

  -- Other feature buttons
  local handler = features[name]
  if handler then
    -- read saved slider values directly from storage
    local sliders = storage.facc_gui_state.sliders
    local radius
    if name == "facc_remove_cliffs"        then radius = sliders["slider_remove_cliffs"] or 50 end
    if name == "facc_remove_nests"         then radius = sliders["slider_remove_nests"] or 50 end
    if name == "facc_reveal_map"           then radius = sliders["slider_reveal_map"] or 150 end
    if name == "facc_convert_to_legendary" then radius = sliders["slider_convert_to_legendary"] or 75 end

    if radius then
      handler.run(player, radius)
    else
      handler.run(player)
    end
  end
end)

--------------------------------------------------------------------------------
-- Slider Changed: update adjacent textbox and persist
--------------------------------------------------------------------------------
script.on_event(defines.events.on_gui_value_changed, function(event)
  local elem = event.element
  if not (elem and elem.valid and elem.type == "slider") then return end

  ensure_persistent_state()

  -- update the textfield next to the slider
  local box = elem.parent[elem.name .. "_value"]
  if box and box.valid then
    box.text = tostring(math.floor(elem.slider_value))
  end

  -- save new slider value
  storage.facc_gui_state.sliders[elem.name] = math.floor(elem.slider_value)
end)

--------------------------------------------------------------------------------
-- Switch Toggled: enable/disable and run immediately once
--------------------------------------------------------------------------------
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
  local elem   = event.element
  local player = game.get_player(event.player_index)
  if not (elem and elem.valid and elem.type == "switch" and player) then return end

  ensure_persistent_state()

  local on = (elem.switch_state == "right")
  storage.facc_gui_state.switches[elem.name] = on

  if elem.name == "facc_auto_clean_pollution" then
    if on then
      for _, p in pairs(game.players) do clean_pollution.run(p) end
    end

  elseif elem.name == "facc_auto_instant_research" then
    if on then
      for _, p in pairs(game.players) do instant_research.run(p) end
    end

  elseif elem.name == "facc_cheat_mode" then
    cheat_mode.run(player, on)

  elseif elem.name == "facc_always_day" then
    always_day.run(player, on)

  elseif elem.name == "facc_disable_pollution" then
    disable_pollution.run(player, on)

  elseif elem.name == "facc_disable_friendly_fire" then
    disable_friendly_fire.run(player, on)

  elseif elem.name == "facc_indestructible_builds" then
    indestructible_builds.run(player, on)

  elseif elem.name == "facc_peaceful_mode" then
    peaceful_mode.run(player, on)

  elseif elem.name == "facc_enemy_expansion" then
    enemy_expansion.run(player, on)
  end
end)

--------------------------------------------------------------------------------
-- On Tick: execute loops at exact intervals based on slider seconds
--------------------------------------------------------------------------------
script.on_event(defines.events.on_tick, function(event)
  ensure_persistent_state()
  local s = storage.facc_gui_state

  -- Auto clean pollution
  if s.switches["facc_auto_clean_pollution"] then
    local secs = s.sliders["slider_auto_clean_pollution"] or 60
    if secs >= 1 and (event.tick % (secs * 60) == 0) then
      for _, p in pairs(game.players) do clean_pollution.run(p) end
    end
  end

  -- Auto instant research
  if s.switches["facc_auto_instant_research"] then
    local secs = s.sliders["slider_auto_instant_research"] or 1
    if secs >= 1 and (event.tick % (secs * 60) == 0) then
      for _, p in pairs(game.players) do instant_research.run(p) end
    end
  end
end)
