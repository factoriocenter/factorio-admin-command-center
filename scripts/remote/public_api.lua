-- scripts/remote/public_api.lua
-- Public remote interface for third-party mods to trigger FACC actions.

local main_gui = require("scripts/gui/main_gui")
local console_gui = require("scripts/gui/console_gui")
local teleport_gui = require("scripts/gui/teleport_gui")
local stats_hud = require("scripts/gui/stats_hud")
local flib_table = require("__flib__.table")
local math_util = require("scripts/utils/flib_math")

local clean_pollution = require("scripts/environment/clean_pollution")
local instant_research = require("scripts/cheats/instant_research")
local cheat_mode = require("scripts/cheats/cheat_mode")
local always_day = require("scripts/environment/always_day")
local disable_pollution = require("scripts/environment/disable_pollution")
local surface_properties = require("scripts/environment/surface_properties")
local disable_friendly_fire = require("scripts/combat/disable_friendly_fire")
local peaceful_mode = require("scripts/combat/peaceful_mode")
local enemy_expansion = require("scripts/enemies/enemy_expansion")
local indestructible_builds = require("scripts/combat/indestructible_builds")
local toggle_minable = require("scripts/mining/toggle_minable")
local set_platform_distance = require("scripts/transportation/set_platform_distance")
local teleport_to_planet = require("scripts/planets/teleport_to_planet")
local toggle_trains = require("scripts/trains/toggle_trains")
local distance_bonus = require("scripts/character/distance_bonus")
local ammo_damage_boost = require("scripts/combat/ammo_damage_boost")
local turret_damage_boost = require("scripts/combat/turret_damage_boost")
local set_game_speed = require("scripts/cheats/set_game_speed")
local set_crafting_speed = require("scripts/manufacturing/set_crafting_speed")
local set_mining_speed = require("scripts/mining/set_mining_speed")
local run_faster = require("scripts/character/run_faster")
local increase_robot_speed = require("scripts/logistic-network/increase_robot_speed")
local set_inventory_slots_bonus = require("scripts/character/set_inventory_slots_bonus")
local console_exec = require("scripts/cheats/console")
local ghost_toggle = require("scripts/character/toggle_ghost_character")
local invincible_player = require("scripts/character/invincible_player")
local repair_mined_item = require("scripts/character/repair_mined_item")
local instant_request = require("scripts/logistic-network/instant_request")
local instant_trash = require("scripts/logistic-network/instant_trash")

local features = {
  facc_toggle_editor = require("scripts/cheats/toggle_editor_mode"),
  facc_delete_ownerless = require("scripts/character/delete_ownerless_characters"),
  facc_build_all_ghosts = require("scripts/blueprints/build_all_ghosts"),
  facc_remove_cliffs = require("scripts/environment/remove_cliffs"),
  facc_remove_nests = require("scripts/enemies/remove_enemy_nests"),
  facc_reveal_map = require("scripts/environment/reveal_map"),
  facc_hide_map = require("scripts/environment/hide_map"),
  facc_remove_decon = require("scripts/blueprints/remove_deconstruction_marks"),
  facc_remove_pollution = require("scripts/environment/remove_pollution"),
  facc_repair_rebuild = require("scripts/blueprints/repair_and_rebuild"),
  facc_recharge_energy = require("scripts/power/recharge_energy"),
  facc_ammo_turrets = require("scripts/combat/ammo_to_turrets"),
  facc_increase_resources = require("scripts/planets/increase_resources"),
  facc_unlock_recipes = require("scripts/cheats/unlock_all_recipes"),
  facc_unlock_technologies = require("scripts/cheats/unlock_all_technologies"),
  facc_insert_coins = require("scripts/cheats/insert_coins"),
  facc_remove_ground_items = require("scripts/environment/remove_ground_items"),
  facc_generate_planet_surfaces = require("scripts/planets/generate_planet_surfaces"),
  facc_create_full_armor = require("scripts/armor/create_full_armor"),
  facc_add_robots = require("scripts/logistic-network/add_robots"),
  facc_fill_platform_thrusters = require("scripts/transportation/fill_platform_thrusters"),
  facc_regenerate_resources = require("scripts/planets/regenerate_resources"),
  facc_high_infinite_research_levels = require("scripts/cheats/high_infinite_research_levels"),
  facc_add_infinite_research_levels = require("scripts/cheats/add_infinite_research_levels"),
  facc_ghost_on_death = require("scripts/blueprints/enable_ghost_on_death"),
  facc_indestructible_builds_permanent = require("scripts/combat/indestructible_builds_permanent"),
  facc_non_minable_permanent = require("scripts/mining/non_minable_permanent")
}

local quality_enabled = script.active_mods["quality"] ~= nil
if quality_enabled then
  features.facc_convert_inventory = require("scripts/character/convert_inventory_to_legendary")
  features.facc_upgrade_blueprints = require("scripts/blueprints/upgrade_blueprints_to_legendary")
  features.facc_convert_to_legendary = require("scripts/blueprints/convert_constructions_to_legendary")
end

local function ensure_state()
  if main_gui and main_gui.ensure_persistent_state then
    main_gui.ensure_persistent_state()
  end
end

local function get_state()
  ensure_state()
  return storage and storage.facc_gui_state or nil
end

local function get_player(player_index)
  if type(player_index) ~= "number" then
    return nil, "invalid-player-index"
  end
  local player = game.get_player(player_index)
  if not (player and player.valid) then
    return nil, "player-not-found"
  end
  return player
end

local function to_boolean(value)
  if type(value) == "boolean" then return value end
  if type(value) == "number" then return value ~= 0 end
  if type(value) == "string" then
    local v = string.lower(value)
    return v == "1" or v == "true" or v == "on" or v == "yes"
  end
  return false
end

local function to_number(value, fallback)
  local n = tonumber(value)
  if n == nil then return fallback end
  return n
end

local function call_safe(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    return false, tostring(err)
  end
  return true, nil
end

local function set_switch_state(name, enabled)
  local state = get_state()
  if not state then return end
  state.switches[name] = enabled
end

local function set_slider_state(name, value)
  local state = get_state()
  if not state then return end
  state.sliders[name] = value
end

local function apply_slider(player, slider_name, new_value, apply_fn, explicit_old)
  local state = get_state()
  if not state then
    return false, "state-not-available"
  end
  local old_value = explicit_old
  if old_value == nil then
    old_value = state.sliders[slider_name] or 0
  end
  local ok, err = call_safe(apply_fn, player, old_value, new_value)
  if not ok then
    return false, err
  end
  state.sliders[slider_name] = new_value
  return true, nil
end

local function handle_feature_action(action, player, args)
  local handler = features[action]
  if not handler then
    return false, "unknown-action"
  end

  local radius = nil
  if action == "facc_remove_cliffs" then radius = to_number(args.radius, 50) end
  if action == "facc_remove_nests" then radius = to_number(args.radius, 50) end
  if action == "facc_reveal_map" then radius = to_number(args.radius, 150) end
  if action == "facc_convert_to_legendary" then radius = to_number(args.radius, 75) end

  if radius ~= nil then
    return call_safe(handler.run, player, radius)
  end
  return call_safe(handler.run, player)
end

local TOGGLE_HANDLERS = {
  facc_cheat_mode = function(player, enabled) return call_safe(cheat_mode.run, player, enabled) end,
  facc_always_day = function(player, enabled) return call_safe(always_day.run, player, enabled) end,
  facc_disable_pollution = function(player, enabled) return call_safe(disable_pollution.run, player, enabled) end,
  facc_disable_friendly_fire = function(player, enabled) return call_safe(disable_friendly_fire.run, player, enabled) end,
  facc_indestructible_builds = function(player, enabled) return call_safe(indestructible_builds.run, player, enabled) end,
  facc_peaceful_mode = function(player, enabled) return call_safe(peaceful_mode.run, player, enabled) end,
  facc_enemy_expansion = function(player, enabled) return call_safe(enemy_expansion.run, player, enabled) end,
  facc_toggle_minable = function(player, enabled) return call_safe(toggle_minable.run, player, enabled) end,
  facc_toggle_trains = function(player, enabled) return call_safe(toggle_trains.run, player, enabled) end,
  facc_ghost_mode = function(player, enabled) return call_safe(ghost_toggle.run, player, enabled) end,
  facc_invincible_player = function(player, enabled) return call_safe(invincible_player.run, player, enabled) end,
  facc_repair_mined_item = function(player, enabled) return call_safe(repair_mined_item.toggle_player, player, enabled) end,
  facc_instant_request = function(player, enabled) return call_safe(instant_request.toggle_player, player, enabled) end,
  facc_instant_trash = function(player, enabled) return call_safe(instant_trash.toggle_player, player, enabled) end,
  facc_surface_freeze_daytime = function(player, enabled) return call_safe(surface_properties.set_freeze_daytime, player, enabled) end,
  facc_surface_peaceful_mode = function(player, enabled) return call_safe(surface_properties.set_peaceful_mode, player, enabled) end,
  facc_surface_no_enemies_mode = function(player, enabled) return call_safe(surface_properties.set_no_enemies_mode, player, enabled) end,
  facc_auto_clean_pollution = function(_player, _enabled)
    flib_table.for_each(game.players, function(p)
      clean_pollution.run(p)
    end)
    return true, nil
  end,
  facc_auto_instant_research = function(_player, _enabled)
    flib_table.for_each(game.players, function(p)
      instant_research.run(p)
    end)
    return true, nil
  end,
  -- state-only switches used by on_tick/event pipelines:
  facc_instant_blueprint_building = function() return true, nil end,
  facc_instant_deconstruction = function() return true, nil end,
  facc_instant_upgrading = function() return true, nil end,
  facc_instant_rail_planner = function() return true, nil end,
}

local VALUE_HANDLERS = {
  facc_set_game_speed = function(player, args)
    local speed = to_number(args.value, 1)
    return call_safe(set_game_speed.run, player, speed)
  end,
  facc_set_mining_speed = function(player, args)
    local value = to_number(args.value, 0)
    return call_safe(set_mining_speed.run, player, value)
  end,
  facc_run_faster = function(player, args)
    local value = to_number(args.value, 0)
    return call_safe(run_faster.run, player, value)
  end,
  facc_set_platform_distance = function(player, args)
    local value = to_number(args.value, 0.99)
    set_slider_state("slider_platform_distance", value)
    return call_safe(set_platform_distance.run, player, value)
  end,
  facc_set_crafting_speed = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_set_crafting_speed", new_value, set_crafting_speed.run, old_value)
  end,
  facc_increase_robot_speed = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_increase_robot_speed", new_value, increase_robot_speed.apply, old_value)
  end,
  facc_ammo_damage_boost = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_ammo_damage_boost", new_value, ammo_damage_boost.apply, old_value)
  end,
  facc_turret_damage_boost = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_turret_damage_boost", new_value, turret_damage_boost.apply, old_value)
  end,
  facc_build_distance = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_build_distance", new_value, function(p, old, new)
      distance_bonus.apply(p, "character_build_distance_bonus", old, new)
    end, old_value)
  end,
  facc_reach_distance = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_reach_distance", new_value, function(p, old, new)
      distance_bonus.apply(p, "character_reach_distance_bonus", old, new)
    end, old_value)
  end,
  facc_resource_reach_distance = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_resource_reach_distance", new_value, function(p, old, new)
      distance_bonus.apply(p, "character_resource_reach_distance_bonus", old, new)
    end, old_value)
  end,
  facc_item_drop_distance = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_item_drop_distance", new_value, function(p, old, new)
      distance_bonus.apply(p, "character_item_drop_distance_bonus", old, new)
    end, old_value)
  end,
  facc_item_pickup_distance = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_item_pickup_distance", new_value, function(p, old, new)
      distance_bonus.apply(p, "character_item_pickup_distance_bonus", old, new)
    end, old_value)
  end,
  facc_loot_pickup_distance = function(player, args)
    local new_value = to_number(args.value, 0)
    local old_value = to_number(args.old_value, nil)
    return apply_slider(player, "slider_loot_pickup_distance", new_value, function(p, old, new)
      distance_bonus.apply(p, "character_loot_pickup_distance_bonus", old, new)
    end, old_value)
  end,
  facc_surface_daytime = function(player, args)
    local value = to_number(args.value, 0.5)
    if value > 1 then
      value = value / 100
    end
    value = math_util.clamp_number(value, 0, 1, 0.5)
    set_slider_state("slider_surface_daytime", math.floor(value * 100))
    return call_safe(surface_properties.set_daytime, player, value)
  end,
  facc_surface_pressure = function(player, args)
    local value = to_number(args.value, 1000)
    set_slider_state("slider_surface_pressure", value)
    return call_safe(surface_properties.set_property, player, "pressure", value)
  end,
  facc_surface_magnetic_field = function(player, args)
    local value = to_number(args.value, 90)
    set_slider_state("slider_surface_magnetic_field", value)
    return call_safe(surface_properties.set_property, player, "magnetic-field", value)
  end,
  facc_surface_gravity = function(player, args)
    local value = to_number(args.value, 10)
    set_slider_state("slider_surface_gravity", value)
    return call_safe(surface_properties.set_property, player, "gravity", value)
  end,
  facc_auto_clean_pollution_interval = function(_player, args)
    local value = math_util.clamp_number(to_number(args.value, 60), 1, 300, 60)
    set_slider_state("slider_auto_clean_pollution", value)
    return true, nil
  end,
  facc_auto_instant_research_interval = function(_player, args)
    local value = math_util.clamp_number(to_number(args.value, 1), 1, 300, 1)
    set_slider_state("slider_auto_instant_research", value)
    return true, nil
  end,
  facc_set_inventory_slots_bonus = function(player, args)
    local value = to_number(args.value, 0)
    local ok, err = call_safe(set_inventory_slots_bonus.run, player, value)
    if not ok then
      return false, err
    end
    return true, nil
  end,
}

local SIMPLE_ACTIONS = {
  facc_surface_daytime_midday = function(player, _args) return call_safe(surface_properties.set_midday, player) end,
  facc_surface_daytime_midnight = function(player, _args) return call_safe(surface_properties.set_midnight, player) end,
  facc_teleport_to_planet = function(player, args)
    local planet_name = args.planet_name or args.value
    if type(planet_name) ~= "string" or planet_name == "" then
      return false, "missing-planet-name"
    end
    return call_safe(teleport_to_planet.run, player, planet_name)
  end,
  facc_console_exec = function(player, args)
    local code = args.code or ""
    if type(code) ~= "string" or code == "" then
      return false, "missing-code"
    end
    return call_safe(console_exec.exec, player, code)
  end,
  facc_console = function(player, _args)
    return call_safe(console_gui.toggle_console_gui, player)
  end,
  facc_toggle_main_gui = function(player, _args)
    return call_safe(main_gui.toggle_main_gui, player)
  end,
  facc_refresh_main_gui = function(player, _args)
    return call_safe(main_gui.refresh_open_gui, player)
  end,
  facc_refresh_stats_hud = function(player, _args)
    return call_safe(stats_hud.refresh_player, player)
  end,
  facc_tp_open = function(player, _args)
    return call_safe(teleport_gui.toggle_teleport_gui, player)
  end,
}

local ACTION_SPEC = {
  run = {
    "facc_toggle_editor", "facc_delete_ownerless", "facc_build_all_ghosts",
    "facc_remove_cliffs", "facc_remove_nests", "facc_reveal_map", "facc_hide_map",
    "facc_remove_decon", "facc_remove_pollution", "facc_repair_rebuild",
    "facc_recharge_energy", "facc_ammo_turrets", "facc_increase_resources",
    "facc_unlock_recipes", "facc_unlock_technologies", "facc_insert_coins",
    "facc_remove_ground_items", "facc_generate_planet_surfaces", "facc_create_full_armor",
    "facc_add_robots", "facc_regenerate_resources", "facc_high_infinite_research_levels",
    "facc_add_infinite_research_levels", "facc_ghost_on_death",
    "facc_indestructible_builds_permanent", "facc_non_minable_permanent",
    "facc_fill_platform_thrusters"
  },
  toggle = {
    "facc_cheat_mode", "facc_always_day", "facc_disable_pollution",
    "facc_disable_friendly_fire", "facc_indestructible_builds", "facc_peaceful_mode",
    "facc_enemy_expansion", "facc_toggle_minable", "facc_toggle_trains",
    "facc_ghost_mode", "facc_invincible_player", "facc_repair_mined_item",
    "facc_instant_request", "facc_instant_trash", "facc_surface_freeze_daytime",
    "facc_surface_peaceful_mode", "facc_surface_no_enemies_mode",
    "facc_auto_clean_pollution", "facc_auto_instant_research",
    "facc_instant_blueprint_building", "facc_instant_deconstruction",
    "facc_instant_upgrading", "facc_instant_rail_planner"
  },
  value = {
    "facc_set_game_speed", "facc_set_mining_speed", "facc_run_faster",
    "facc_set_platform_distance", "facc_set_crafting_speed", "facc_increase_robot_speed",
    "facc_ammo_damage_boost", "facc_turret_damage_boost", "facc_build_distance",
    "facc_reach_distance", "facc_resource_reach_distance", "facc_item_drop_distance",
    "facc_item_pickup_distance", "facc_loot_pickup_distance", "facc_surface_daytime",
    "facc_surface_pressure", "facc_surface_magnetic_field", "facc_surface_gravity",
    "facc_auto_clean_pollution_interval", "facc_auto_instant_research_interval",
    "facc_set_inventory_slots_bonus"
  },
  simple = {
    "facc_surface_daytime_midday", "facc_surface_daytime_midnight",
    "facc_teleport_to_planet", "facc_console_exec", "facc_console",
    "facc_toggle_main_gui", "facc_refresh_main_gui", "facc_refresh_stats_hud",
    "facc_tp_open"
  }
}

if quality_enabled then
  ACTION_SPEC.run[#ACTION_SPEC.run + 1] = "facc_convert_inventory"
  ACTION_SPEC.run[#ACTION_SPEC.run + 1] = "facc_upgrade_blueprints"
  ACTION_SPEC.run[#ACTION_SPEC.run + 1] = "facc_convert_to_legendary"
end

local NO_PLAYER_ACTIONS = {
  facc_auto_clean_pollution = true,
  facc_auto_instant_research = true,
  facc_instant_blueprint_building = true,
  facc_instant_deconstruction = true,
  facc_instant_upgrading = true,
  facc_instant_rail_planner = true,
  facc_auto_clean_pollution_interval = true,
  facc_auto_instant_research_interval = true,
}

local ACTION_INFO = {}
for kind, names in pairs(ACTION_SPEC) do
  for _, name in ipairs(names) do
    ACTION_INFO[name] = {
      kind = kind,
      requires_player = not NO_PLAYER_ACTIONS[name]
    }
  end
end

local ACTION_SCHEMA = {
  facc_remove_cliffs = { radius = "number (default 50)" },
  facc_remove_nests = { radius = "number (default 50)" },
  facc_reveal_map = { radius = "number (default 150)" },
  facc_convert_to_legendary = { radius = "number (default 75)" },
  facc_set_game_speed = { value = "number" },
  facc_set_mining_speed = { value = "number" },
  facc_run_faster = { value = "number" },
  facc_set_platform_distance = { value = "number [0..1]" },
  facc_set_crafting_speed = { value = "number", old_value = "number (optional)" },
  facc_increase_robot_speed = { value = "number", old_value = "number (optional)" },
  facc_ammo_damage_boost = { value = "number", old_value = "number (optional)" },
  facc_turret_damage_boost = { value = "number", old_value = "number (optional)" },
  facc_build_distance = { value = "number", old_value = "number (optional)" },
  facc_reach_distance = { value = "number", old_value = "number (optional)" },
  facc_resource_reach_distance = { value = "number", old_value = "number (optional)" },
  facc_item_drop_distance = { value = "number", old_value = "number (optional)" },
  facc_item_pickup_distance = { value = "number", old_value = "number (optional)" },
  facc_loot_pickup_distance = { value = "number", old_value = "number (optional)" },
  facc_surface_daytime = { value = "number [0..1] or [0..100]" },
  facc_surface_pressure = { value = "number" },
  facc_surface_magnetic_field = { value = "number" },
  facc_surface_gravity = { value = "number" },
  facc_auto_clean_pollution_interval = { value = "number seconds [1..300]" },
  facc_auto_instant_research_interval = { value = "number seconds [1..300]" },
  facc_set_inventory_slots_bonus = { value = "number [0..65535], min 10 if toolbelt researched" },
  facc_teleport_to_planet = { planet_name = "string (or use value)" },
  facc_console_exec = { code = "string (Lua code)" },
  facc_refresh_stats_hud = {},
  facc_tp_open = {},
}

local function run_action_impl(action, player_index, args)
  if type(action) ~= "string" or action == "" then
    return { ok = false, error = "missing-action" }
  end
  args = type(args) == "table" and args or {}

  local player = nil
  if not NO_PLAYER_ACTIONS[action] then
    local player_err = nil
    player, player_err = get_player(player_index)
    if not player then
      return { ok = false, error = player_err }
    end
  end

  if features[action] then
    local ok, err = handle_feature_action(action, player, args)
    return { ok = ok, error = err, action = action }
  end

  local toggle_handler = TOGGLE_HANDLERS[action]
  if toggle_handler then
    local enabled = to_boolean(args.enabled ~= nil and args.enabled or args.value)
    set_switch_state(action, enabled)
    local ok, err = toggle_handler(player, enabled)
    return { ok = ok, error = err, action = action, enabled = enabled }
  end

  local value_handler = VALUE_HANDLERS[action]
  if value_handler then
    local ok, err = value_handler(player, args)
    return { ok = ok, error = err, action = action }
  end

  local simple_handler = SIMPLE_ACTIONS[action]
  if simple_handler then
    local ok, err = simple_handler(player, args)
    return { ok = ok, error = err, action = action }
  end

  return { ok = false, error = "unknown-action", action = action }
end

local INTERFACE_NAME = "facc"
local INTERFACE_ALIAS = "factorio_admin_command_center"
local INTERFACE_VERSION = 1
local function list_planets()
  local result = {}
  local seen = {}
  local base_order = { "nauvis", "vulcanus", "fulgora", "gleba", "aquilo" }

  for _, name in ipairs(base_order) do
    if not seen[name] then
      seen[name] = true
      result[#result + 1] = name
    end
  end

  if game.planets then
    for name in pairs(game.planets) do
      if not seen[name] then
        seen[name] = true
        result[#result + 1] = name
      end
    end
  end

  return result
end

local API_FUNCTIONS = {
  get_interface_version = function()
    return INTERFACE_VERSION
  end,

  get_mod_version = function()
    return script.active_mods["factorio-admin-command-center"] or "unknown"
  end,

  get_capabilities = function()
    return {
      quality = script.active_mods["quality"] ~= nil,
      space_age = script.active_mods["space-age"] ~= nil,
      planets = list_planets()
    }
  end,

  ping = function()
    return { ok = true, pong = true, interface = INTERFACE_NAME, version = INTERFACE_VERSION }
  end,

  list_actions = function()
    return ACTION_SPEC
  end,

  get_action_info = function(action)
    local info = ACTION_INFO[action]
    if not info then
      return nil
    end
    return {
      kind = info.kind,
      requires_player = info.requires_player,
      schema = ACTION_SCHEMA[action]
    }
  end,

  has_action = function(action)
    if type(action) ~= "string" then return false end
    if features[action] then return true end
    if TOGGLE_HANDLERS[action] then return true end
    if VALUE_HANDLERS[action] then return true end
    if SIMPLE_ACTIONS[action] then return true end
    return false
  end,

  run_action = function(action, player_index, args)
    return run_action_impl(action, player_index, args)
  end,

  run_batch = function(calls)
    if type(calls) ~= "table" then
      return { ok = false, error = "invalid-calls-table" }
    end
    local results = {}
    for i, item in ipairs(calls) do
      if type(item) == "table" then
        results[#results + 1] = run_action_impl(item.action, item.player_index, item.args)
      else
        results[#results + 1] = { ok = false, error = "invalid-call-item", index = i }
      end
    end
    return { ok = true, results = results }
  end,

  set_toggle = function(action, player_index, enabled)
    return run_action_impl(action, player_index, { enabled = enabled })
  end,

  set_value = function(action, player_index, value, old_value)
    return run_action_impl(action, player_index, { value = value, old_value = old_value })
  end,

  toggle_main_gui = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err = call_safe(main_gui.toggle_main_gui, player)
    return { ok = ok, error = call_err }
  end,

  toggle_console_gui = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err = call_safe(console_gui.toggle_console_gui, player)
    return { ok = ok, error = call_err }
  end,

  toggle_teleport_gui = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err = call_safe(teleport_gui.toggle_teleport_gui, player)
    return { ok = ok, error = call_err }
  end,

  refresh_stats_hud = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err = call_safe(stats_hud.refresh_player, player)
    return { ok = ok, error = call_err }
  end,

  get_stats_hud_snapshot = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end

    local ok, snapshot_or_err = pcall(stats_hud.get_snapshot, player)
    if not ok then
      return { ok = false, error = tostring(snapshot_or_err) }
    end

    return { ok = true, snapshot = snapshot_or_err or {} }
  end,

  get_stats_hud_capabilities = function()
    return {
      ok = true,
      order = {
        "coordinates_distance",
        "daytime",
        "playtime",
        "evolution",
        "pollution",
        "research_eta",
        "movement_speed",
        "handcraft_timer",
      },
      sensors = {
        coordinates_distance = true,
        daytime = true,
        playtime = true,
        evolution = true,
        pollution = true,
        research_eta = true,
        movement_speed = true,
        movement_speed_player_max = true,
        movement_speed_vehicle_max = true,
        movement_speed_vehicle_fuel = true,
        platform_propellant = true,
        handcraft_timer = true,
      },
      source_mods = {
        "StatsGui",
        "StatsGui-CoordinatesDistance",
        "StatsGui-HandcraftTimer",
        "StatsGui-MovementSpeed",
      },
    }
  end,

  list_saved_teleports = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, points = teleport_gui.list_saved_points(player)
    return { ok = ok, error = call_err, points = points or {} }
  end,

  save_current_teleport = function(player_index, name)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, point = teleport_gui.save_current_point(player, name)
    return { ok = ok, error = call_err, point = point }
  end,

  rename_saved_teleport = function(player_index, point_id, new_name)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, point = teleport_gui.rename_saved_point(player, tonumber(point_id), new_name)
    return { ok = ok, error = call_err, point = point }
  end,

  delete_saved_teleport = function(player_index, point_id)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err = teleport_gui.delete_saved_point(player, tonumber(point_id))
    return { ok = ok, error = call_err }
  end,

  teleport_to_saved = function(player_index, point_id)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, point = teleport_gui.teleport_to_saved_point(player, tonumber(point_id))
    return { ok = ok, error = call_err, point = point }
  end,

  list_tag_teleports = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, tags = teleport_gui.list_visible_tags(player)
    return { ok = ok, error = call_err, tags = tags or {} }
  end,

  teleport_to_tag = function(player_index, tag_number)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, tag = teleport_gui.teleport_to_tag(player, tonumber(tag_number))
    return { ok = ok, error = call_err, tag = tag }
  end,

  hide_tag_teleport = function(player_index, tag_number)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, tag = teleport_gui.hide_tag(player, tonumber(tag_number))
    return { ok = ok, error = call_err, tag = tag }
  end,

  unhide_tag_teleports = function(player_index)
    local player, err = get_player(player_index)
    if not player then return { ok = false, error = err } end
    local ok, call_err, count = teleport_gui.unhide_all_tags(player)
    return { ok = ok, error = call_err, count = count or 0 }
  end,
}

local function register_interface(name)
  if remote.interfaces[name] then
    remote.remove_interface(name)
  end
  remote.add_interface(name, API_FUNCTIONS)
end

register_interface(INTERFACE_NAME)
register_interface(INTERFACE_ALIAS)
