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

local toggle_trains          = require("scripts/trains/toggle_trains")
local long_reach             = require("scripts/character/long_reach")
local ammo_damage_boost      = require("scripts/combat/ammo_damage_boost")
local turret_damage_boost    = require("scripts/combat/turret_damage_boost")
local enable_ghost_on_death   = require("scripts/blueprints/enable_ghost_on_death")

-- new auto-run slider handlers
local set_game_speed         = require("scripts/cheats/set_game_speed")
local set_crafting_speed     = require("scripts/manufacturing/set_crafting_speed")
local set_mining_speed       = require("scripts/mining/set_mining_speed")
local run_faster             = require("scripts/character/run_faster")
local increase_robot_speed   = require("scripts/logistic-network/increase_robot_speed")

local ghost_toggle         = require("scripts/character/toggle_ghost_character")

local ensure_state = main_gui.ensure_persistent_state

-- Whitelists of FACC GUI element names
local FACC_BUTTONS = {
  -- Main and console buttons
  facc_main_button=true,
  facc_close_main_gui=true,
  facc_console=true,
  facc_console_exec=true,
  facc_console_close=true,
  -- Feature buttons
  facc_toggle_editor=true,
  facc_delete_ownerless=true,
  facc_build_all_ghosts=true,
  facc_remove_cliffs=true,
  facc_remove_nests=true,
  facc_reveal_map=true,
  facc_hide_map=true,
  facc_remove_decon=true,
  facc_remove_pollution=true,
  facc_repair_rebuild=true,
  facc_recharge_energy=true,
  facc_ammo_turrets=true,
  facc_increase_resources=true,
  facc_unlock_recipes=true,
  facc_unlock_technologies=true,
  facc_insert_coins=true,
  facc_remove_ground_items=true,
  facc_generate_planet_surfaces=true,
  facc_create_full_armor=true,
  facc_add_robots=true,
  facc_regenerate_resources=true,
  facc_high_infinite_research_levels = true,
  -- Legendary features
  facc_convert_inventory=true,
  facc_upgrade_blueprints=true,
  facc_convert_to_legendary=true,
  -- Platform distance confirm
  facc_set_platform_distance=true
}

local FACC_SLIDERS = {
  slider_set_game_speed=true,
  slider_set_crafting_speed=true,
  slider_set_mining_speed=true,
  slider_run_faster=true,
  slider_platform_distance=true,
  slider_remove_cliffs=true,
  slider_remove_nests=true,
  slider_reveal_map=true,
  slider_convert_to_legendary=true,
  slider_auto_clean_pollution=true,
  slider_auto_instant_research=true,
  slider_increase_robot_speed=true,
  slider_long_reach=true,
  slider_ammo_damage_boost=true,
  slider_turret_damage_boost=true,
}

local FACC_SWITCHES = {
  facc_auto_clean_pollution=true,
  facc_auto_instant_research=true,
  facc_cheat_mode=true,
  facc_always_day=true,
  facc_disable_pollution=true,
  facc_disable_friendly_fire=true,
  facc_indestructible_builds=true,
  facc_peaceful_mode=true,
  facc_enemy_expansion=true,
  facc_toggle_minable=true,
  facc_toggle_trains=true,
  facc_ghost_on_death = true,
  facc_instant_blueprint_building = true,
  facc_instant_deconstruction     = true,
  facc_instant_upgrading          = true,
  facc_instant_rail_planner       = true,
  facc_ghost_mode = true,
}

-- Base feature handlers
local features = {
  facc_toggle_editor        = require("scripts/cheats/toggle_editor_mode"),
  facc_delete_ownerless     = require("scripts/character/delete_ownerless_characters"),
  facc_build_all_ghosts     = require("scripts/blueprints/build_all_ghosts"),
  facc_remove_cliffs        = require("scripts/environment/remove_cliffs"),
  facc_remove_nests         = require("scripts/enemies/remove_enemy_nests"),
  facc_reveal_map           = require("scripts/environment/reveal_map"),
  facc_hide_map             = require("scripts/environment/hide_map"),
  facc_remove_decon         = require("scripts/blueprints/remove_deconstruction_marks"),
  facc_remove_pollution     = require("scripts/environment/remove_pollution"),
  facc_repair_rebuild       = require("scripts/blueprints/repair_and_rebuild"),
  facc_recharge_energy      = require("scripts/power/recharge_energy"),
  facc_ammo_turrets         = require("scripts/combat/ammo_to_turrets"),
  facc_increase_resources   = require("scripts/planets/increase_resources"),
  facc_unlock_recipes       = require("scripts/cheats/unlock_all_recipes"),
  facc_unlock_technologies  = require("scripts/cheats/unlock_all_technologies"),
  facc_insert_coins         = require("scripts/cheats/insert_coins"),
  facc_remove_ground_items  = require("scripts/environment/remove_ground_items"),
  facc_generate_planet_surfaces = require("scripts/planets/generate_planet_surfaces"),
  facc_create_full_armor    = require("scripts/armor/create_full_armor"),
  facc_add_robots           = require("scripts/logistic-network/add_robots"),
  facc_regenerate_resources = require("scripts/planets/regenerate_resources"),
  facc_high_infinite_research_levels = require("scripts/cheats/high_infinite_research_levels"),
}

-- Legendary-only handlers
local quality_enabled   = script.active_mods["quality"]    ~= nil
local space_age_enabled = script.active_mods["space-age"] ~= nil

if quality_enabled then
  features.facc_convert_inventory    = require("scripts/character/convert_inventory_to_legendary")
  features.facc_upgrade_blueprints   = require("scripts/blueprints/upgrade_blueprints_to_legendary")
  features.facc_convert_to_legendary = require("scripts/blueprints/convert_constructions_to_legendary")
end

-- Click dispatcher (FACC-only buttons)
script.on_event(defines.events.on_gui_click, function(event)
  local player, element = game.get_player(event.player_index), event.element
  if not (player and element and element.valid) then return end
  local name = element.name
  if not FACC_BUTTONS[name] then return end

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

    if radius then handler.run(player, radius)
    else           handler.run(player)
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

-- Slider change handler (auto-run for FACC-only sliders)
script.on_event(defines.events.on_gui_value_changed, function(event)
  local elem = event.element
  if not (elem and elem.valid and elem.type == "slider" and FACC_SLIDERS[elem.name]) then return end
  ensure_state()
  local player = game.get_player(event.player_index)

  -- Handle Increase Robot Speed as a true live slider
  if elem.name == "slider_increase_robot_speed" then
    local old = storage.facc_gui_state.sliders["slider_increase_robot_speed"] or 0
    local new = elem.slider_value
    increase_robot_speed.apply(player, old, new)
    storage.facc_gui_state.sliders["slider_increase_robot_speed"] = new
    local box = elem.parent[elem.name .. "_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

    -- Live‐slider: Long Reach
  if elem.name == "slider_long_reach" then
    local old = storage.facc_gui_state.sliders["slider_long_reach"] or 0
    local new = elem.slider_value
    long_reach.apply(player, old, new)
    storage.facc_gui_state.sliders["slider_long_reach"] = new
    local box = elem.parent["slider_long_reach_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  -- Live‐slider: Ammo Damage Boost
  if elem.name == "slider_ammo_damage_boost" then
    local old = storage.facc_gui_state.sliders["slider_ammo_damage_boost"] or 0
    local new = elem.slider_value
    ammo_damage_boost.apply(player, old, new)
    storage.facc_gui_state.sliders["slider_ammo_damage_boost"] = new
    local box = elem.parent["slider_ammo_damage_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  -- Live‐slider: Turret Damage Boost
  if elem.name == "slider_turret_damage_boost" then
    local old = storage.facc_gui_state.sliders["slider_turret_damage_boost"] or 0
    local new = elem.slider_value
    turret_damage_boost.apply(player, old, new)
    storage.facc_gui_state.sliders["slider_turret_damage_boost"] = new
    local box = elem.parent["slider_turret_damage_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  -- Handle Set Crafting Speed as a true live slider
  if elem.name == "slider_set_crafting_speed" then
    local old = storage.facc_gui_state.sliders["slider_set_crafting_speed"] or 0
    local new = elem.slider_value
    set_crafting_speed.run(player, old, new)
    storage.facc_gui_state.sliders["slider_set_crafting_speed"] = new
    local box = elem.parent[elem.name .. "_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  -- Default behavior for other sliders
  storage.facc_gui_state.sliders[elem.name] = elem.slider_value
  local box = elem.parent[elem.name .. "_value"]
  if box and box.valid then box.text = tostring(elem.slider_value) end

  if elem.name == "slider_set_game_speed" then
    local speeds = {0.25, 0.5, 1, 2, 4, 8, 16, 32, 64}
    local idx   = math.floor(elem.slider_value)
    local speed = speeds[idx] or 1
    set_game_speed.run(player, speed)
    if box and box.valid then box.text = tostring(speed) end

  elseif elem.name == "slider_set_mining_speed" then
    set_mining_speed.run(player, elem.slider_value)

  elseif elem.name == "slider_platform_distance" then
    set_platform_distance.run(player, elem.slider_value)

  elseif elem.name == "slider_run_faster" then
    run_faster.run(player, elem.slider_value)
  end
end)

-- Switch toggle handler (FACC-only switches)
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
  local elem   = event.element
  local player = game.get_player(event.player_index)
  if not (elem and elem.valid and elem.type == "switch" and player and FACC_SWITCHES[elem.name]) then return end
  ensure_state()
  local on = (elem.switch_state == "right")
  storage.facc_gui_state.switches[elem.name] = on

  if     elem.name == "facc_auto_clean_pollution"   then for _,p in pairs(game.players) do clean_pollution.run(p) end
  elseif elem.name == "facc_auto_instant_research"  then for _,p in pairs(game.players) do instant_research.run(p) end
  elseif elem.name == "facc_cheat_mode"             then cheat_mode.run(player, on)
  elseif elem.name == "facc_always_day"             then always_day.run(player, on)
  elseif elem.name == "facc_disable_pollution"      then disable_pollution.run(player, on)
  elseif elem.name == "facc_disable_friendly_fire"  then disable_friendly_fire.run(player, on)
  elseif elem.name == "facc_indestructible_builds"  then indestructible_builds.run(player, on)
  elseif elem.name == "facc_peaceful_mode"          then peaceful_mode.run(player, on)
  elseif elem.name == "facc_enemy_expansion"        then enemy_expansion.run(player, on)
  elseif elem.name == "facc_toggle_minable"         then toggle_minable.run(player, on)
  elseif elem.name == "facc_toggle_trains"          then toggle_trains.run(player, on)
  elseif elem.name == "facc_ghost_on_death"         then enable_ghost_on_death.run(player, on)
  elseif elem.name == "facc_ghost_mode"           then ghost_toggle.run(player, on)
  end
  -- The new 3.6.0 switches don't need immediate side-effects; the dispatcher reads them live.
end)
