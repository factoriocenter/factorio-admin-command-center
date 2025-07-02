-- scripts/events/gui_events.lua
-- GUI event dispatcher for FACC.
-- Handles clicks, slider changes, switch toggles and on-tick loops.

local main_gui               = require("scripts/gui/main_gui")
local console_gui            = require("scripts/gui/console_gui")
local clean_pollution        = require("scripts/environment/clean_pollution")
local instant_research       = require("scripts/cheats/instant_research")
local cheat_mode             = require("scripts/cheats/cheat_mode")

local always_day             = require("scripts/environment/always_day")
local disable_pollution      = require("scripts/environment/disable_pollution")

local disable_friendly_fire  = require("scripts/combat/disable_friendly_fire")
local peaceful_mode          = require("scripts/combat/peaceful_mode")
local enemy_expansion        = require("scripts/enemies/enemy_expansion")
local indestructible_builds  = require("scripts/combat/indestructible_builds")

local toggle_minable         = require("scripts/mining/toggle_minable")
local set_platform_distance  = require("scripts/transportation/set_platform_distance")

local ensure_state = main_gui.ensure_persistent_state

-- Base feature handlers
local features = {
  facc_toggle_editor        = require("scripts/cheats/toggle_editor_mode"),
  facc_delete_ownerless     = require("scripts/character/delete_ownerless_characters"),
  facc_build_all_ghosts     = require("scripts/blueprints/build_all_ghosts"),
  facc_remove_cliffs        = require("scripts/environment/remove_cliffs"),
  facc_remove_nests         = require("scripts/enemies/remove_enemy_nests"),
  facc_reveal_map           = require("scripts/environment/reveal_map"),
  facc_hide_map             = require("scripts/environment/hide_map"),
  facc_remove_decon         = require("scripts/environment/remove_deconstruction_marks"),
  facc_remove_pollution     = require("scripts/environment/remove_pollution"),
  facc_repair_rebuild       = require("scripts/environment/repair_and_rebuild"),
  facc_recharge_energy      = require("scripts/power/recharge_energy"),
  facc_ammo_turrets         = require("scripts/combat/ammo_to_turrets"),
  facc_increase_resources   = require("scripts/environment/increase_resources"),
  facc_unlock_recipes       = require("scripts/cheats/unlock_all_recipes"),
  facc_unlock_technologies  = require("scripts/cheats/unlock_all_technologies"),
  facc_insert_coins         = require("scripts/cheats/insert_coins"),
}

-- Legendary-only handlers
local quality_enabled   = script.active_mods["quality"]    ~= nil
local space_age_enabled = script.active_mods["space-age"] ~= nil

if quality_enabled then
  features.facc_convert_inventory      = require("scripts/character/convert_inventory_to_legendary")
  features.facc_upgrade_blueprints     = require("scripts/blueprints/upgrade_blueprints_to_legendary")
  features.facc_convert_to_legendary   = require("scripts/blueprints/convert_constructions_to_legendary")
  if space_age_enabled then
    -- corrected path: armor, not character
    features.facc_create_legendary_armor = require("scripts/armor/create_legendary_armor")
  end
end

-- Click dispatcher
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
  if name == "facc_console_exec"  then console_gui.exec_console_command(player); return end
  if name == "facc_console_close" then console_gui.toggle_console_gui(player); return end

  -- Standard feature buttons
  local handler = features[name]
  if handler then
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
    return
  end

  -- Platform Distance confirm button
  if name == "facc_set_platform_distance" then
    local raw = storage.facc_gui_state.sliders["slider_platform_distance"] or 0.99
    set_platform_distance.run(player, raw)
    return
  end
end)

-- Slider change handler
script.on_event(defines.events.on_gui_value_changed, function(event)
  local elem = event.element
  if not (elem and elem.valid and elem.type == "slider") then return end
  ensure_state()
  local box = elem.parent[elem.name .. "_value"]
  if box and box.valid then box.text = tostring(elem.slider_value) end
  storage.facc_gui_state.sliders[elem.name] = elem.slider_value
end)

-- Switch toggle handler
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
  local elem   = event.element
  local player = game.get_player(event.player_index)
  if not (elem and elem.valid and elem.type == "switch" and player) then return end
  ensure_state()
  local on = (elem.switch_state == "right")
  storage.facc_gui_state.switches[elem.name] = on

  if     elem.name == "facc_auto_clean_pollution"   then for _, p in pairs(game.players) do clean_pollution.run(p) end
  elseif elem.name == "facc_auto_instant_research"  then for _, p in pairs(game.players) do instant_research.run(p) end
  elseif elem.name == "facc_cheat_mode"             then cheat_mode.run(player, on)
  elseif elem.name == "facc_always_day"             then always_day.run(player, on)
  elseif elem.name == "facc_disable_pollution"      then disable_pollution.run(player, on)
  elseif elem.name == "facc_disable_friendly_fire"  then disable_friendly_fire.run(player, on)
  elseif elem.name == "facc_indestructible_builds"  then indestructible_builds.run(player, on)
  elseif elem.name == "facc_peaceful_mode"          then peaceful_mode.run(player, on)
  elseif elem.name == "facc_enemy_expansion"        then enemy_expansion.run(player, on)
  elseif elem.name == "facc_toggle_minable"         then toggle_minable.run(player, on)
  end
end)

-- On-tick for the two automations
script.on_event(defines.events.on_tick, function(event)
  ensure_state()
  local s = storage.facc_gui_state
  if s.switches["facc_auto_clean_pollution"] then
    local secs = s.sliders["slider_auto_clean_pollution"] or 60
    if secs >= 1 and (event.tick % (secs * 60) == 0) then
      for _, p in pairs(game.players) do clean_pollution.run(p) end
    end
  end
  if s.switches["facc_auto_instant_research"] then
    local secs = s.sliders["slider_auto_instant_research"] or 1
    if secs >= 1 and (event.tick % (secs * 60) == 0) then
      for _, p in pairs(game.players) do instant_research.run(p) end
    end
  end
end)
