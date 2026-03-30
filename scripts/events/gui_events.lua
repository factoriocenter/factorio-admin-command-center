-- scripts/events/gui_events.lua
-- GUI event handlers for FACC, registered through FLib GUI dispatch.

local M = {}

local flib_gui               = require("__flib__.gui")
local clean_pollution        = require("scripts/environment/clean_pollution")
local instant_research       = require("scripts/cheats/instant_research")
local cheat_mode             = require("scripts/cheats/cheat_mode")

local always_day             = require("scripts/environment/always_day")
local disable_pollution      = require("scripts/environment/disable_pollution")
local surface_properties     = require("scripts/environment/surface_properties")

local disable_friendly_fire  = require("scripts/combat/disable_friendly_fire")
local peaceful_mode          = require("scripts/combat/peaceful_mode")
local enemy_expansion        = require("scripts/enemies/enemy_expansion")
local indestructible_builds  = require("scripts/combat/indestructible_builds")

local toggle_minable         = require("scripts/mining/toggle_minable")
local set_platform_distance  = require("scripts/transportation/set_platform_distance")
local teleport_to_planet     = require("scripts/planets/teleport_to_planet")

local toggle_trains          = require("scripts/trains/toggle_trains")
local distance_bonus         = require("scripts/character/distance_bonus")
local ammo_damage_boost      = require("scripts/combat/ammo_damage_boost")
local turret_damage_boost    = require("scripts/combat/turret_damage_boost")
local gun_speed_boost        = require("scripts/combat/gun_speed_boost")
local artillery_range_boost  = require("scripts/combat/artillery_range_boost")
local character_health_bonus = require("scripts/character/character_health_bonus")
local robot_storage_bonus    = require("scripts/logistic-network/robot_storage_bonus")
local robot_battery_bonus    = require("scripts/logistic-network/robot_battery_bonus")
local following_robot_lifetime_bonus = require("scripts/logistic-network/following_robot_lifetime_bonus")
local maximum_following_robot_count = require("scripts/logistic-network/maximum_following_robot_count")
local inserter_stack_size_bonus = require("scripts/logistic-network/inserter_stack_size_bonus")
local bulk_inserter_capacity_bonus = require("scripts/logistic-network/bulk_inserter_capacity_bonus")
local belt_stack_size_bonus = require("scripts/logistic-network/belt_stack_size_bonus")
local beacon_distribution_bonus = require("scripts/logistic-network/beacon_distribution_bonus")
local laboratory_speed_bonus = require("scripts/cheats/laboratory_speed_bonus")
local laboratory_productivity_bonus = require("scripts/cheats/laboratory_productivity_bonus")
local mining_drill_productivity_bonus = require("scripts/mining/mining_drill_productivity_bonus")
local train_braking_force_bonus = require("scripts/trains/train_braking_force_bonus")
local solar_power_multiplier = require("scripts/power/solar_power_multiplier")

-- live auto-run sliders
local set_game_speed         = require("scripts/cheats/set_game_speed")
local set_crafting_speed     = require("scripts/character/set_crafting_speed")
local set_mining_speed       = require("scripts/mining/set_mining_speed")
local run_faster             = require("scripts/character/run_faster")
local increase_robot_speed   = require("scripts/logistic-network/increase_robot_speed")
local set_inventory_slots_bonus = require("scripts/character/set_inventory_slots_bonus")
local set_character_trash_slot_bonus = require("scripts/character/set_character_trash_slot_bonus")
local compat                 = require("scripts/utils/mod_compat")

-- Character features
local ghost_toggle           = require("scripts/character/toggle_ghost_character")
local invincible_player      = require("scripts/character/invincible_player")
local repair_mined_item      = require("scripts/character/repair_mined_item")

-- Logistics helpers
local instant_request        = require("scripts/logistic-network/instant_request")
local instant_trash          = require("scripts/logistic-network/instant_trash")
local math_util              = require("scripts/utils/flib_math")
local flib_table             = require("__flib__.table")

local main_gui_api = nil
local console_gui_api = nil
local teleport_gui_api = nil

function M.set_main_gui_api(api)
  main_gui_api = api
end

function M.set_console_gui_api(api)
  console_gui_api = api
end

function M.set_teleport_gui_api(api)
  teleport_gui_api = api
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

local function safe_call(action_name, fn, ...)
  local ok, result_or_err = pcall(fn, ...)
  if not ok then
    log("[FACC][GUI] " .. tostring(action_name) .. " failed: " .. tostring(result_or_err))
    return false
  end
  return true, result_or_err
end

local function safe_call_player(player, action_name, fn, ...)
  local ok, result_a, result_b = safe_call(action_name, fn, ...)
  if not ok and player and player.valid then
    player.print({"facc.runtime-compat-error", action_name})
  end
  return ok, result_a, result_b
end

local function find_descendant(root, name)
  if not (root and root.valid and type(name) == "string" and name ~= "") then
    return nil
  end
  if root.children then
    for _, child in pairs(root.children) do
      if child and child.valid then
        if child.name == name then
          return child
        end
        local nested = find_descendant(child, name)
        if nested then
          return nested
        end
      end
    end
  end
  return nil
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
  facc_create_full_tank=true,
  facc_create_full_spidertron=true,
  facc_add_robots=true,
  facc_regenerate_resources=true,
  facc_high_infinite_research_levels = true,
  facc_add_infinite_research_levels = true,
  facc_indestructible_builds_permanent = true,
  facc_non_minable_permanent = true,
  facc_set_inventory_slots_bonus = true,
  facc_character_trash_slot_bonus = true,
  facc_ghost_on_death = true,
  -- Legendary features (Quality DLC)
  facc_convert_inventory=true,
  facc_upgrade_blueprints=true,
  -- Platform distance confirm
  facc_set_platform_distance=true,
  facc_fill_platform_thrusters=true,
  facc_surface_daytime=true,
  facc_surface_daytime_midday=true,
  facc_surface_daytime_midnight=true,
  facc_surface_pressure=true,
  facc_surface_magnetic_field=true,
  facc_surface_gravity=true,
  facc_surface_solar_power_multiplier=true,
}

local FACC_SLIDERS = {
  slider_set_game_speed=true,
  slider_set_crafting_speed=true,
  slider_set_mining_speed=true,
  slider_run_faster=true,
  slider_character_health_bonus=true,
  slider_platform_distance=true,
  slider_remove_cliffs=true,
  slider_remove_nests=true,
  slider_reveal_map=true,
  slider_auto_clean_pollution=true,
  slider_auto_instant_research=true,
  slider_increase_robot_speed=true,
  slider_robot_storage_bonus=true,
  slider_robot_battery_bonus=true,
  slider_following_robot_lifetime_bonus=true,
  slider_build_distance=true,
  slider_reach_distance=true,
  slider_resource_reach_distance=true,
  slider_item_drop_distance=true,
  slider_item_pickup_distance=true,
  slider_loot_pickup_distance=true,
  slider_ammo_damage_boost=true,
  slider_turret_damage_boost=true,
  slider_gun_speed_boost=true,
  slider_artillery_range_boost=true,
  slider_laboratory_speed_bonus=true,
  slider_laboratory_productivity_bonus=true,
  slider_inserter_stack_size_bonus=true,
  slider_bulk_inserter_capacity_bonus=true,
  slider_belt_stack_size_bonus=true,
  slider_maximum_following_robot_count=true,
  slider_mining_drill_productivity_bonus=true,
  slider_train_braking_force_bonus=true,
  slider_beacon_distribution_bonus=true,
  slider_surface_daytime=true,
  slider_surface_pressure=true,
  slider_surface_magnetic_field=true,
  slider_surface_gravity=true,
  slider_surface_solar_power_multiplier=true,
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
  facc_repair_mined_item = true,
  facc_instant_request = true,
  facc_instant_trash = true,
  facc_surface_freeze_daytime = true,
  facc_surface_peaceful_mode = true,
  facc_surface_no_enemies_mode = true,
}

local DISTANCE_SLIDERS = {
  slider_build_distance = "character_build_distance_bonus",
  slider_reach_distance = "character_reach_distance_bonus",
  slider_resource_reach_distance = "character_resource_reach_distance_bonus",
  slider_item_drop_distance = "character_item_drop_distance_bonus",
  slider_item_pickup_distance = "character_item_pickup_distance_bonus",
  slider_loot_pickup_distance = "character_loot_pickup_distance_bonus",
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
  facc_create_full_tank = require("scripts/transportation/create_full_tank"),
  facc_create_full_spidertron = require("scripts/transportation/create_full_spidertron"),
  facc_add_robots           = require("scripts/logistic-network/add_robots"),
  facc_fill_platform_thrusters = require("scripts/transportation/fill_platform_thrusters"),
  facc_regenerate_resources = require("scripts/planets/regenerate_resources"),
  facc_high_infinite_research_levels = require("scripts/cheats/high_infinite_research_levels"),
  facc_add_infinite_research_levels = require("scripts/cheats/add_infinite_research_levels"),
  facc_ghost_on_death = require("scripts/blueprints/enable_ghost_on_death"),
  facc_indestructible_builds_permanent = require("scripts/combat/indestructible_builds_permanent"),
  facc_non_minable_permanent = require("scripts/mining/non_minable_permanent"),
  facc_set_inventory_slots_bonus = set_inventory_slots_bonus,
  facc_character_trash_slot_bonus = set_character_trash_slot_bonus,
}

local quality_enabled = compat.is_quality_active()
if quality_enabled then
  features.facc_convert_inventory    = require("scripts/character/convert_inventory_to_legendary")
  features.facc_upgrade_blueprints   = require("scripts/blueprints/upgrade_blueprints_to_legendary")
end

local function on_menu_selection_state_changed(event)
  local elem = event.element
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  local name = elem and elem.valid and elem.name or ""
  if string.sub(name, 1, 8) == "facc_tp_" then
    if teleport_gui_api and teleport_gui_api.handle_selection_state_changed then
      teleport_gui_api.handle_selection_state_changed(player, elem)
    end
    return
  end

  if not (elem and elem.valid and elem.name == "facc_menu_list") then return end
  ensure_state()
  if main_gui_api and main_gui_api.handle_tab_selection then
    main_gui_api.handle_tab_selection(player, elem.selected_index)
  end
end

local function on_gui_click(event)
  local player, element = game.get_player(event.player_index), event.element
  if not (player and element and element.valid) then return end
  local name = element.name
  local is_teleport_gui_button = string.sub(name, 1, 8) == "facc_tp_"
  if is_teleport_gui_button then
    if teleport_gui_api and teleport_gui_api.handle_click then
      teleport_gui_api.handle_click(player, element)
    end
    return
  end
  local is_planet_teleport_button = string.sub(name, 1, 22) == "facc_teleport_planet__"
  if not FACC_BUTTONS[name] and not is_planet_teleport_button then return end
  local state = get_state()
  if not state then return end

  if is_planet_teleport_button then
    local planet_name = string.sub(name, 23)
    safe_call_player(player, "teleport_to_planet", teleport_to_planet.run, player, planet_name)
    return
  end

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
    if name == "facc_set_inventory_slots_bonus" then
      if type(state.inputs) ~= "table" then
        state.inputs = {}
      end

      local bonus_state_key = "input_inventory_slots_bonus_bonus"
      local old_bonus = state.sliders[bonus_state_key]
      if old_bonus == nil then
        old_bonus = tonumber(state.inputs["input_inventory_slots_bonus"]) or 0
      end
      local raw_value = state.inputs["input_inventory_slots_bonus"] or "0"
      local ok, applied_value, _minimum, applied_bonus = safe_call_player(player, name, handler.run, player, old_bonus, raw_value)
      if not ok then
        return
      end

      if applied_value ~= nil then
        local display_bonus = tonumber(applied_bonus)
        if display_bonus == nil then
          display_bonus = tonumber(raw_value) or 0
        end
        local text_value = tostring(math.floor(display_bonus))
        state.inputs["input_inventory_slots_bonus"] = text_value
        state.sliders[bonus_state_key] = math.floor(display_bonus)
        local frame = player.gui.screen["facc_main_frame"]
        local input = find_descendant(frame, "input_inventory_slots_bonus")
        if input and input.valid then
          input.text = text_value
        end
      end

      return
    end

    if name == "facc_character_trash_slot_bonus" then
      if type(state.inputs) ~= "table" then
        state.inputs = {}
      end

      local bonus_state_key = "input_character_trash_slot_bonus_bonus"
      local old_bonus = state.sliders[bonus_state_key]
      if old_bonus == nil then
        old_bonus = tonumber(state.inputs["input_character_trash_slot_bonus"]) or 0
      end
      local raw_value = state.inputs["input_character_trash_slot_bonus"] or "0"
      local ok, applied_value, _minimum, applied_bonus = safe_call_player(player, name, handler.run, player, old_bonus, raw_value)
      if not ok then
        return
      end

      if applied_value ~= nil then
        local display_bonus = tonumber(applied_bonus)
        if display_bonus == nil then
          display_bonus = tonumber(raw_value) or 0
        end
        local text_value = tostring(math.floor(display_bonus))
        state.inputs["input_character_trash_slot_bonus"] = text_value
        state.sliders[bonus_state_key] = math.floor(display_bonus)
        local frame = player.gui.screen["facc_main_frame"]
        local input = find_descendant(frame, "input_character_trash_slot_bonus")
        if input and input.valid then
          input.text = text_value
        end
      end

      return
    end

    local sliders = state.sliders
    local radius
    if name == "facc_remove_cliffs"        then radius = sliders["slider_remove_cliffs"] or 50 end
    if name == "facc_remove_nests"         then radius = sliders["slider_remove_nests"] or 50 end
    if name == "facc_reveal_map"           then radius = sliders["slider_reveal_map"] or 150 end

    if radius then
      safe_call_player(player, name, handler.run, player, radius)
    else
      safe_call_player(player, name, handler.run, player)
    end
    return
  end

  if name == "facc_set_platform_distance" then
    local raw = state.sliders["slider_platform_distance"] or 0.99
    safe_call_player(player, name, set_platform_distance.run, player, raw)
    return
  end

  if name == "facc_surface_daytime" then
    local daytime_pct = state.sliders["slider_surface_daytime"] or 50
    safe_call_player(player, name, surface_properties.set_daytime, player, daytime_pct / 100)
    return
  end

  if name == "facc_surface_daytime_midday" then
    safe_call_player(player, name, surface_properties.set_midday, player)
    return
  end

  if name == "facc_surface_daytime_midnight" then
    safe_call_player(player, name, surface_properties.set_midnight, player)
    return
  end

  if name == "facc_surface_pressure" then
    local pressure = state.sliders["slider_surface_pressure"] or 1000
    safe_call_player(player, name, surface_properties.set_property, player, "pressure", pressure)
    return
  end

  if name == "facc_surface_magnetic_field" then
    local magnetic = state.sliders["slider_surface_magnetic_field"] or 90
    safe_call_player(player, name, surface_properties.set_property, player, "magnetic-field", magnetic)
    return
  end

  if name == "facc_surface_gravity" then
    local gravity = state.sliders["slider_surface_gravity"] or 10
    safe_call_player(player, name, surface_properties.set_property, player, "gravity", gravity)
    return
  end

  if name == "facc_surface_solar_power_multiplier" then
    local multiplier = state.sliders["slider_surface_solar_power_multiplier"] or 1
    safe_call_player(player, name, solar_power_multiplier.run, player, multiplier)
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
    safe_call_player(player, elem.name, increase_robot_speed.apply, player, old, new)
    state.sliders["slider_increase_robot_speed"] = new
    local box = elem.parent[elem.name .. "_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_character_health_bonus" then
    local old = state.sliders["slider_character_health_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, character_health_bonus.apply, player, old, new)
    state.sliders["slider_character_health_bonus"] = new
    local box = elem.parent["slider_character_health_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_robot_storage_bonus" then
    local old = state.sliders["slider_robot_storage_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, robot_storage_bonus.apply, player, old, new)
    state.sliders["slider_robot_storage_bonus"] = new
    local box = elem.parent["slider_robot_storage_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_robot_battery_bonus" then
    local old = state.sliders["slider_robot_battery_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, robot_battery_bonus.apply, player, old, new)
    state.sliders["slider_robot_battery_bonus"] = new
    local box = elem.parent["slider_robot_battery_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_following_robot_lifetime_bonus" then
    local old = state.sliders["slider_following_robot_lifetime_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, following_robot_lifetime_bonus.apply, player, old, new)
    state.sliders["slider_following_robot_lifetime_bonus"] = new
    local box = elem.parent["slider_following_robot_lifetime_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_maximum_following_robot_count" then
    local old = state.sliders["slider_maximum_following_robot_count"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, maximum_following_robot_count.apply, player, old, new)
    state.sliders["slider_maximum_following_robot_count"] = new
    local box = elem.parent["slider_maximum_following_robot_count_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_inserter_stack_size_bonus" then
    local old = state.sliders["slider_inserter_stack_size_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, inserter_stack_size_bonus.apply, player, old, new)
    state.sliders["slider_inserter_stack_size_bonus"] = new
    local box = elem.parent["slider_inserter_stack_size_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_bulk_inserter_capacity_bonus" then
    local old = state.sliders["slider_bulk_inserter_capacity_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, bulk_inserter_capacity_bonus.apply, player, old, new)
    state.sliders["slider_bulk_inserter_capacity_bonus"] = new
    local box = elem.parent["slider_bulk_inserter_capacity_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_belt_stack_size_bonus" then
    local old = state.sliders["slider_belt_stack_size_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, belt_stack_size_bonus.apply, player, old, new)
    state.sliders["slider_belt_stack_size_bonus"] = new
    local box = elem.parent["slider_belt_stack_size_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_beacon_distribution_bonus" then
    local old = state.sliders["slider_beacon_distribution_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, beacon_distribution_bonus.apply, player, old, new)
    state.sliders["slider_beacon_distribution_bonus"] = new
    local box = elem.parent["slider_beacon_distribution_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  local distance_property = DISTANCE_SLIDERS[elem.name]
  if distance_property then
    local old = state.sliders[elem.name] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, distance_bonus.apply, player, distance_property, old, new)
    state.sliders[elem.name] = new
    local box = elem.parent[elem.name .. "_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_ammo_damage_boost" then
    local old = state.sliders["slider_ammo_damage_boost"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, ammo_damage_boost.apply, player, old, new)
    state.sliders["slider_ammo_damage_boost"] = new
    local box = elem.parent["slider_ammo_damage_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_turret_damage_boost" then
    local old = state.sliders["slider_turret_damage_boost"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, turret_damage_boost.apply, player, old, new)
    state.sliders["slider_turret_damage_boost"] = new
    local box = elem.parent["slider_turret_damage_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_gun_speed_boost" then
    local old = state.sliders["slider_gun_speed_boost"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, gun_speed_boost.apply, player, old, new)
    state.sliders["slider_gun_speed_boost"] = new
    local box = elem.parent["slider_gun_speed_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_artillery_range_boost" then
    local old = state.sliders["slider_artillery_range_boost"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, artillery_range_boost.apply, player, old, new)
    state.sliders["slider_artillery_range_boost"] = new
    local box = elem.parent["slider_artillery_range_boost_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_laboratory_speed_bonus" then
    local old = state.sliders["slider_laboratory_speed_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, laboratory_speed_bonus.apply, player, old, new)
    state.sliders["slider_laboratory_speed_bonus"] = new
    local box = elem.parent["slider_laboratory_speed_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_laboratory_productivity_bonus" then
    local old = state.sliders["slider_laboratory_productivity_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, laboratory_productivity_bonus.apply, player, old, new)
    state.sliders["slider_laboratory_productivity_bonus"] = new
    local box = elem.parent["slider_laboratory_productivity_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_mining_drill_productivity_bonus" then
    local old = state.sliders["slider_mining_drill_productivity_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, mining_drill_productivity_bonus.apply, player, old, new)
    state.sliders["slider_mining_drill_productivity_bonus"] = new
    local box = elem.parent["slider_mining_drill_productivity_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_train_braking_force_bonus" then
    local old = state.sliders["slider_train_braking_force_bonus"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, train_braking_force_bonus.apply, player, old, new)
    state.sliders["slider_train_braking_force_bonus"] = new
    local box = elem.parent["slider_train_braking_force_bonus_value"]
    if box and box.valid then box.text = tostring(new) end
    return
  end

  if elem.name == "slider_surface_daytime" then
    local new = elem.slider_value
    state.sliders["slider_surface_daytime"] = new
    local box = elem.parent["slider_surface_daytime_value"]
    if box and box.valid then
      box.text = string.format("%.2f", new / 100)
    end
    return
  end

  if elem.name == "slider_set_crafting_speed" then
    local old = state.sliders["slider_set_crafting_speed"] or 0
    local new = elem.slider_value
    safe_call_player(player, elem.name, set_crafting_speed.run, player, old, new)
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
    safe_call_player(player, elem.name, set_game_speed.run, player, speed)
    if box and box.valid then box.text = tostring(speed) end
  elseif elem.name == "slider_set_mining_speed" then
    safe_call_player(player, elem.name, set_mining_speed.run, player, elem.slider_value)
  elseif elem.name == "slider_platform_distance" then
    safe_call_player(player, elem.name, set_platform_distance.run, player, elem.slider_value)
  elseif elem.name == "slider_run_faster" then
    safe_call_player(player, elem.name, run_faster.run, player, elem.slider_value)
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
      safe_call_player(p, elem.name, clean_pollution.run, p)
    end)
  elseif elem.name == "facc_auto_instant_research"  then
    flib_table.for_each(game.players, function(p)
      safe_call_player(p, elem.name, instant_research.run, p)
    end)
  elseif elem.name == "facc_cheat_mode"             then safe_call_player(player, elem.name, cheat_mode.run, player, on)
  elseif elem.name == "facc_always_day"             then safe_call_player(player, elem.name, always_day.run, player, on)
  elseif elem.name == "facc_disable_pollution"      then safe_call_player(player, elem.name, disable_pollution.run, player, on)
  elseif elem.name == "facc_disable_friendly_fire"  then safe_call_player(player, elem.name, disable_friendly_fire.run, player, on)
  elseif elem.name == "facc_indestructible_builds"  then safe_call_player(player, elem.name, indestructible_builds.run, player, on)
  elseif elem.name == "facc_peaceful_mode"          then safe_call_player(player, elem.name, peaceful_mode.run, player, on)
  elseif elem.name == "facc_enemy_expansion"        then safe_call_player(player, elem.name, enemy_expansion.run, player, on)
  elseif elem.name == "facc_toggle_minable"         then safe_call_player(player, elem.name, toggle_minable.run, player, on)
  elseif elem.name == "facc_toggle_trains"          then safe_call_player(player, elem.name, toggle_trains.run, player, on)
  elseif elem.name == "facc_ghost_mode"             then safe_call_player(player, elem.name, ghost_toggle.run, player, on)
  elseif elem.name == "facc_invincible_player"      then safe_call_player(player, elem.name, invincible_player.run, player, on)
  elseif elem.name == "facc_repair_mined_item"      then safe_call_player(player, elem.name, repair_mined_item.toggle_player, player, on)
  elseif elem.name == "facc_instant_request"        then safe_call_player(player, elem.name, instant_request.toggle_player, player, on)
  elseif elem.name == "facc_instant_trash"          then safe_call_player(player, elem.name, instant_trash.toggle_player, player, on)
  elseif elem.name == "facc_surface_freeze_daytime" then safe_call_player(player, elem.name, surface_properties.set_freeze_daytime, player, on)
  elseif elem.name == "facc_surface_peaceful_mode"  then safe_call_player(player, elem.name, surface_properties.set_peaceful_mode, player, on)
  elseif elem.name == "facc_surface_no_enemies_mode" then safe_call_player(player, elem.name, surface_properties.set_no_enemies_mode, player, on)
  end
end

local function on_console_text_changed(event)
  local elem = event.element
  if not (elem and elem.valid) then
    return
  end

  if elem.name == "facc_textbox" then
    storage.facc_last_command = elem.text or ""
    return
  end

  if elem.name == "input_inventory_slots_bonus" or elem.name == "input_character_trash_slot_bonus" then
    local state = get_state()
    if not state then
      return
    end
    if type(state.inputs) ~= "table" then
      state.inputs = {}
    end
    state.inputs[elem.name] = elem.text or ""
  end
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
