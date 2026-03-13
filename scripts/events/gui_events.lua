-- scripts/events/gui_events.lua
-- GUI event handlers for FACC, registered through FLib GUI dispatch.

local M = {}

local flib_gui               = require("__flib__.gui")
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

-- live auto-run sliders
local set_game_speed         = require("scripts/cheats/set_game_speed")
local set_crafting_speed     = require("scripts/manufacturing/set_crafting_speed")
local set_mining_speed       = require("scripts/mining/set_mining_speed")
local run_faster             = require("scripts/character/run_faster")
local increase_robot_speed   = require("scripts/logistic-network/increase_robot_speed")

-- Character features
local ghost_toggle           = require("scripts/character/toggle_ghost_character")
local invincible_player      = require("scripts/character/invincible_player")

-- Logistics helpers
local instant_request        = require("scripts/logistic-network/instant_request")
local instant_trash          = require("scripts/logistic-network/instant_trash")
local math_util              = require("scripts/utils/flib_math")
local flib_table             = require("__flib__.table")

local main_gui_api = nil
local console_gui_api = nil

function M.set_main_gui_api(api)
  main_gui_api = api
end

function M.set_console_gui_api(api)
  console_gui_api = api
end

local function ensure_state()
  if main_gui_api and main_gui_api.ensure_persistent_state then
    main_gui_api.ensure_persistent_state()
  end
end

local function get_state()
  ensure_state()
  return storage and storage.facc_gui_state or nil
end

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
  facc_add_infinite_research_levels = true,
  facc_indestructible_builds_permanent = true,
  facc_non_minable_permanent = true,
  facc_ghost_on_death = true,
  -- Legendary features (Quality DLC)
  facc_convert_inventory=true,
  facc_upgrade_blueprints=true,
  facc_convert_to_legendary=true,
  -- Platform distance confirm
  facc_set_platform_distance=true,
  facc_fill_platform_thrusters=true
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
  facc_instant_blueprint_building = true,
  facc_instant_deconstruction     = true,
  facc_instant_upgrading          = true,
  facc_instant_rail_planner       = true,
  facc_ghost_mode = true,
  facc_invincible_player = true,
  facc_instant_request = true,
  facc_instant_trash = true,
}

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
  facc_fill_platform_thrusters = require("scripts/transportation/fill_platform_thrusters"),
  facc_regenerate_resources = require("scripts/planets/regenerate_resources"),
  facc_high_infinite_research_levels = require("scripts/cheats/high_infinite_research_levels"),
  facc_add_infinite_research_levels = require("scripts/cheats/add_infinite_research_levels"),
  facc_ghost_on_death = require("scripts/blueprints/enable_ghost_on_death"),
  facc_indestructible_builds_permanent = require("scripts/combat/indestructible_builds_permanent"),
  facc_non_minable_permanent = require("scripts/mining/non_minable_permanent"),
}

local quality_enabled = script.active_mods["quality"] ~= nil
if quality_enabled then
  features.facc_convert_inventory    = require("scripts/character/convert_inventory_to_legendary")
  features.facc_upgrade_blueprints   = require("scripts/blueprints/upgrade_blueprints_to_legendary")
  features.facc_convert_to_legendary = require("scripts/blueprints/convert_constructions_to_legendary")
end

local function on_menu_selection_state_changed(event)
  local elem = event.element
  if not (elem and elem.valid and elem.name == "facc_menu_list") then return end
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  ensure_state()
  if main_gui_api and main_gui_api.handle_tab_selection then
    main_gui_api.handle_tab_selection(player, elem.selected_index)
  end
end

local function on_gui_click(event)
  local player, element = game.get_player(event.player_index), event.element
  if not (player and element and element.valid) then return end
  local name = element.name
  if not FACC_BUTTONS[name] then return end
  local state = get_state()
  if not state then return end

  if name == "facc_main_button" or name == "facc_close_main_gui" then
    if main_gui_api and main_gui_api.toggle_main_gui then
      main_gui_api.toggle_main_gui(player)
    end
    return
  end

  if name == "facc_console" then
    if console_gui_api and console_gui_api.toggle_console_gui then
      console_gui_api.toggle_console_gui(player)
    end
    return
  end
  if name == "facc_console_exec" then
    if console_gui_api and console_gui_api.exec_console_command then
      console_gui_api.exec_console_command(player)
    end
    return
  end
  if name == "facc_console_close" then
    if console_gui_api and console_gui_api.toggle_console_gui then
      console_gui_api.toggle_console_gui(player)
    end
    return
  end

  local handler = features[name]
  if handler then
    local sliders = state.sliders
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

  if name == "facc_set_platform_distance" then
    local raw = state.sliders["slider_platform_distance"] or 0.99
    set_platform_distance.run(player, raw)
  end
end

local function on_gui_value_changed(event)
  local elem = event.element
  if not (elem and elem.valid and elem.type == "slider" and FACC_SLIDERS[elem.name]) then return end
  local state = get_state()
  if not state then return end
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  if elem.name == "slider_increase_robot_speed" then
    local old = state.sliders["slider_increase_robot_speed"] or 0
    local new = elem.slider_value
    increase_robot_speed.apply(player, old, new)
    state.sliders["slider_increase_robot_speed"] = new
    local box = elem.parent[elem.name .. "_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_long_reach" then
    local old = state.sliders["slider_long_reach"] or 0
    local new = elem.slider_value
    long_reach.apply(player, old, new)
    state.sliders["slider_long_reach"] = new
    local box = elem.parent["slider_long_reach_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_ammo_damage_boost" then
    local old = state.sliders["slider_ammo_damage_boost"] or 0
    local new = elem.slider_value
    ammo_damage_boost.apply(player, old, new)
    state.sliders["slider_ammo_damage_boost"] = new
    local box = elem.parent["slider_ammo_damage_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_turret_damage_boost" then
    local old = state.sliders["slider_turret_damage_boost"] or 0
    local new = elem.slider_value
    turret_damage_boost.apply(player, old, new)
    state.sliders["slider_turret_damage_boost"] = new
    local box = elem.parent["slider_turret_damage_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_set_crafting_speed" then
    local old = state.sliders["slider_set_crafting_speed"] or 0
    local new = elem.slider_value
    set_crafting_speed.run(player, old, new)
    state.sliders["slider_set_crafting_speed"] = new
    local box = elem.parent[elem.name .. "_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  state.sliders[elem.name] = elem.slider_value
  local box = elem.parent[elem.name .. "_value"]
  if box and box.valid then box.text = tostring(elem.slider_value) end

  if elem.name == "slider_set_game_speed" then
    local speeds = {0.25, 0.5, 1, 2, 4, 8, 16, 32, 64}
    local idx = math_util.floor(elem.slider_value)
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
end

local function on_gui_switch_state_changed(event)
  local elem   = event.element
  local player = game.get_player(event.player_index)
  if not (elem and elem.valid and elem.type == "switch" and player and FACC_SWITCHES[elem.name]) then return end
  local state = get_state()
  if not state then return end
  local on = (elem.switch_state == "right")
  state.switches[elem.name] = on

  if     elem.name == "facc_auto_clean_pollution"   then
    flib_table.for_each(game.players, function(p)
      clean_pollution.run(p)
    end)
  elseif elem.name == "facc_auto_instant_research"  then
    flib_table.for_each(game.players, function(p)
      instant_research.run(p)
    end)
  elseif elem.name == "facc_cheat_mode"             then cheat_mode.run(player, on)
  elseif elem.name == "facc_always_day"             then always_day.run(player, on)
  elseif elem.name == "facc_disable_pollution"      then disable_pollution.run(player, on)
  elseif elem.name == "facc_disable_friendly_fire"  then disable_friendly_fire.run(player, on)
  elseif elem.name == "facc_indestructible_builds"  then indestructible_builds.run(player, on)
  elseif elem.name == "facc_peaceful_mode"          then peaceful_mode.run(player, on)
  elseif elem.name == "facc_enemy_expansion"        then enemy_expansion.run(player, on)
  elseif elem.name == "facc_toggle_minable"         then toggle_minable.run(player, on)
  elseif elem.name == "facc_toggle_trains"          then toggle_trains.run(player, on)
  elseif elem.name == "facc_ghost_mode"             then ghost_toggle.run(player, on)
  elseif elem.name == "facc_invincible_player"      then invincible_player.run(player, on)
  elseif elem.name == "facc_instant_request"        then instant_request.toggle_player(player, on)
  elseif elem.name == "facc_instant_trash"          then instant_trash.toggle_player(player, on)
  end
end

local function on_console_text_changed(event)
  local elem = event.element
  if not (elem and elem.valid and elem.name == "facc_textbox") then
    return
  end
  storage.facc_last_command = elem.text or ""
end

M.handlers = {
  menu_selection = on_menu_selection_state_changed,
  click = on_gui_click,
  slider = on_gui_value_changed,
  switch = on_gui_switch_state_changed,
  console_text_changed = on_console_text_changed
}

local handlers_registered = false

function M.register_handlers()
  if handlers_registered then
    return
  end

  flib_gui.add_handlers({
    menu_selection = M.handlers.menu_selection,
    click = M.handlers.click,
    slider = M.handlers.slider,
    switch = M.handlers.switch,
    console_text_changed = M.handlers.console_text_changed
  }, nil, "facc")

  flib_gui.handle_events()
  handlers_registered = true
end

M.register_handlers()

return M
