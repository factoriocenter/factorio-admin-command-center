-- scripts/events/build_events.lua
-- Single event dispatcher

local instant_bp_build = require("scripts/blueprints/instant_blueprint_building")
local instant_rail     = require("scripts/blueprints/instant_rail_planner")
local instant_decon    = require("scripts/blueprints/instant_deconstruction")
local instant_upgrade  = require("scripts/blueprints/instant_upgrading")
local build_all_ghosts = require("scripts/blueprints/build_all_ghosts")
local remove_decon_marks = require("scripts/blueprints/remove_deconstruction_marks")
local repair_and_rebuild = require("scripts/blueprints/repair_and_rebuild")
local clean_pollution  = require("scripts/environment/clean_pollution")
local hide_map = require("scripts/environment/hide_map")
local remove_ground_items = require("scripts/environment/remove_ground_items")
local instant_research = require("scripts/cheats/instant_research")
local ammo_to_turrets = require("scripts/combat/ammo_to_turrets")
local indestructible_builds = require("scripts/combat/indestructible_builds")
local indestructible_builds_permanent = require("scripts/combat/indestructible_builds_permanent")
local instant_request  = require("scripts/logistic-network/instant_request")
local instant_trash    = require("scripts/logistic-network/instant_trash")
local delete_ownerless_characters = require("scripts/character/delete_ownerless_characters")
local repair_mined_item = require("scripts/character/repair_mined_item")
local toggle_minable = require("scripts/mining/toggle_minable")
local non_minable_permanent = require("scripts/mining/non_minable_permanent")
local increase_resources = require("scripts/planets/increase_resources")
local regenerate_resources = require("scripts/planets/regenerate_resources")
local recharge_energy = require("scripts/power/recharge_energy")
local set_platform_distance = require("scripts/transportation/set_platform_distance")
local main_gui = require("scripts/gui/main_gui")
local flib_on_tick_n = require("__flib__.on-tick-n")
local flib_table = require("__flib__.table")
local math_util = require("scripts/utils/flib_math")

local ensure_state = main_gui.ensure_persistent_state
local restore_gui_on_next_tick = false
local AUTO_TASKS_KEY = "facc_auto_task_ids"
local AUTO_TASK_INTERVALS_KEY = "facc_auto_task_intervals"
local AUTO_TASK_CLEAN = "facc_auto_clean_pollution"
local AUTO_TASK_RESEARCH = "facc_auto_instant_research"
local AUTO_TASK_PLATFORM = "facc_platform_distance_refresh"

local function ensure_auto_task_ids()
  return flib_table.get_or_insert(storage, AUTO_TASKS_KEY, {})
end

local function ensure_auto_task_intervals()
  return flib_table.get_or_insert(storage, AUTO_TASK_INTERVALS_KEY, {})
end

local function interval_to_ticks(seconds)
  return math_util.max(1, math_util.floor((tonumber(seconds) or 1) * 60))
end

local function cancel_auto_task(task_ids, task_intervals, key)
  local ident = task_ids[key]
  if ident then
    flib_on_tick_n.remove(ident)
    task_ids[key] = nil
  end
  task_intervals[key] = nil
end

local function ensure_auto_task(task_ids, task_intervals, key, seconds)
  local ticks = interval_to_ticks(seconds)
  if task_ids[key] and task_intervals[key] == ticks then
    return
  end
  cancel_auto_task(task_ids, task_intervals, key)
  task_ids[key] = flib_on_tick_n.add(game.tick + ticks, key)
  task_intervals[key] = ticks
end

-- Permission gate (best-effort):
local function allowed(player_index)
  local p = player_index and game.get_player(player_index) or nil
  if not p then return false end
  if _G.is_allowed then return is_allowed(p) end
  return true
end

local function safe_call(label, fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    log("[FACC][EVENT] " .. tostring(label) .. " failed: " .. tostring(err))
    return false
  end
  return true
end

local function safe_on_tick(label, mod, event)
  if mod and mod.on_tick then
    safe_call(label .. ".on_tick", mod.on_tick, event)
  end
end

--------------------------------------------------------------------------------
-- Player-built entities: blueprint/rail fast paths
--------------------------------------------------------------------------------
script.on_event(defines.events.on_built_entity, function(e)
  ensure_state()

  local ent = e.entity or e.created_entity
  if not (ent and ent.valid) then return end

  -- Keep tracked logistics entities current even when non-admins build.
  if instant_request.on_entity_created then safe_call("instant_request.on_entity_created", instant_request.on_entity_created, e) end
  if instant_trash.on_entity_created then safe_call("instant_trash.on_entity_created", instant_trash.on_entity_created, e) end

  if not allowed(e.player_index) then return end

  -- Blueprint building pipeline:
  if ent.type == "entity-ghost" or ent.type == "tile-ghost" or ent.type == "item-request-proxy" then
    if storage.facc_gui_state.switches["facc_instant_blueprint_building"] then
      safe_call("instant_bp_build.on_built_entity", instant_bp_build.on_built_entity, e)
      return
    end

    if ent.type == "entity-ghost" and storage.facc_gui_state.switches["facc_instant_rail_planner"] then
      safe_call("instant_rail.on_built_entity", instant_rail.on_built_entity, e)
      return
    end
  end
end)

-- Robot/script-built entities: keep logistics tracking lists in sync.
script.on_event(
  {defines.events.on_robot_built_entity, defines.events.script_raised_built},
  function(e)
    ensure_state()
    if instant_request.on_entity_created then
      safe_call("instant_request.on_entity_created", instant_request.on_entity_created, e)
    end
    if instant_trash.on_entity_created then
      safe_call("instant_trash.on_entity_created", instant_trash.on_entity_created, e)
    end
  end
)

-- Entity removals (death/mined/script): keep logistics tracking lists in sync.
script.on_event(
  {defines.events.on_entity_died, defines.events.on_robot_mined_entity, defines.events.on_player_mined_entity, defines.events.script_raised_destroy},
  function(e)
    ensure_state()
    if instant_request.on_entity_removed then
      safe_call("instant_request.on_entity_removed", instant_request.on_entity_removed, e)
    end
    if instant_trash.on_entity_removed then
      safe_call("instant_trash.on_entity_removed", instant_trash.on_entity_removed, e)
    end
  end
)

script.on_load(function()
  restore_gui_on_next_tick = true
end)

--------------------------------------------------------------------------------
-- Marked for deconstruction: instant removal (entities) → processed on tick
--------------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_deconstruction, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if storage.facc_gui_state.switches["facc_instant_deconstruction"] then
    safe_call("instant_decon.on_marked_for_deconstruction", instant_decon.on_marked_for_deconstruction, e)
  end
end)

--------------------------------------------------------------------------------
-- Player deconstruction selection (tiles) → module decides tile handling
--------------------------------------------------------------------------------
script.on_event(defines.events.on_player_deconstructed_area, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if storage.facc_gui_state.switches["facc_instant_deconstruction"] then
    safe_call("instant_decon.on_player_deconstructed_area", instant_decon.on_player_deconstructed_area, e)
  end
end)

--------------------------------------------------------------------------------
-- Marked for upgrade: instant upgrade
--------------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_upgrade, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if storage.facc_gui_state.switches["facc_instant_upgrading"] then
    safe_call("instant_upgrade.on_marked_for_upgrade", instant_upgrade.on_marked_for_upgrade, e)
  end
end)

--------------------------------------------------------------------------------
-- Repair mined item: repair entity before it gets mined/removed
--------------------------------------------------------------------------------
script.on_event(defines.events.on_pre_player_mined_item, function(e)
  if not allowed(e.player_index) then return end
  safe_call("repair_mined_item.on_pre_player_mined_item", repair_mined_item.on_pre_player_mined_item, e)
end)

--------------------------------------------------------------------------------
-- On-tick: central worker hub (ONLY this file registers on_tick)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_tick, function(event)
  ensure_state()
  local s = storage.facc_gui_state
  local auto_task_ids = ensure_auto_task_ids()
  local auto_task_intervals = ensure_auto_task_intervals()

  if restore_gui_on_next_tick then
    restore_gui_on_next_tick = false
    safe_call("main_gui.restore_open_gui_for_all_players", main_gui.restore_open_gui_for_all_players)
  end

  -- FLib scheduled auto workers
  if s.switches["facc_auto_clean_pollution"] then
    ensure_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_CLEAN, s.sliders["slider_auto_clean_pollution"] or 60)
  else
    cancel_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_CLEAN)
  end

  if s.switches["facc_auto_instant_research"] then
    ensure_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_RESEARCH, s.sliders["slider_auto_instant_research"] or 1)
  else
    cancel_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_RESEARCH)
  end

  if set_platform_distance.on_tick then
    ensure_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_PLATFORM, 1)
  else
    cancel_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_PLATFORM)
  end

  for _, task in pairs(flib_on_tick_n.retrieve(event.tick) or {}) do
    if task == AUTO_TASK_CLEAN then
      auto_task_ids[AUTO_TASK_CLEAN] = nil
      if s.switches["facc_auto_clean_pollution"] then
        flib_table.for_each(game.players, function(p)
          safe_call("clean_pollution.run", clean_pollution.run, p)
        end)
        ensure_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_CLEAN, s.sliders["slider_auto_clean_pollution"] or 60)
      end
    elseif task == AUTO_TASK_RESEARCH then
      auto_task_ids[AUTO_TASK_RESEARCH] = nil
      if s.switches["facc_auto_instant_research"] then
        flib_table.for_each(game.players, function(p)
          safe_call("instant_research.run", instant_research.run, p)
        end)
        ensure_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_RESEARCH, s.sliders["slider_auto_instant_research"] or 1)
      end
    elseif task == AUTO_TASK_PLATFORM then
      auto_task_ids[AUTO_TASK_PLATFORM] = nil
      if set_platform_distance.on_tick then
        safe_call("set_platform_distance.on_tick", set_platform_distance.on_tick, { tick = event.tick })
        ensure_auto_task(auto_task_ids, auto_task_intervals, AUTO_TASK_PLATFORM, 1)
      end
    end
  end

  -- 1) Instant Blueprint Building worker
  if s.switches["facc_instant_blueprint_building"] and instant_bp_build.on_tick then
    safe_call("instant_bp_build.on_tick", instant_bp_build.on_tick, event)
  end

  -- 2) Instant Deconstruction queue
  if s.switches["facc_instant_deconstruction"] and instant_decon.on_tick then
    safe_call("instant_decon.on_tick", instant_decon.on_tick, event)
  end

  -- 3) Instant Request per-player worker (gated by GUI switch)
  if s.switches["facc_instant_request"] and instant_request.on_tick then
    safe_call("instant_request.on_tick", instant_request.on_tick, event)
  end

  -- 4) Instant Trash worker (skip when no player has it enabled)
  if instant_trash.on_tick and instant_trash.has_enabled_players and instant_trash.has_enabled_players() then
    safe_call("instant_trash.on_tick", instant_trash.on_tick, event)
  end

  -- 5) Event-driven background jobs for heavy one-shot actions
  safe_on_tick("build_all_ghosts", build_all_ghosts, event)
  safe_on_tick("remove_decon_marks", remove_decon_marks, event)
  safe_on_tick("repair_and_rebuild", repair_and_rebuild, event)
  safe_on_tick("remove_ground_items", remove_ground_items, event)
  safe_on_tick("recharge_energy", recharge_energy, event)
  safe_on_tick("increase_resources", increase_resources, event)
  safe_on_tick("regenerate_resources", regenerate_resources, event)
  safe_on_tick("hide_map", hide_map, event)
  safe_on_tick("ammo_to_turrets", ammo_to_turrets, event)
  safe_on_tick("delete_ownerless_characters", delete_ownerless_characters, event)
  safe_on_tick("toggle_minable", toggle_minable, event)
  safe_on_tick("non_minable_permanent", non_minable_permanent, event)
  safe_on_tick("indestructible_builds", indestructible_builds, event)
  safe_on_tick("indestructible_builds_permanent", indestructible_builds_permanent, event)

end)

-- PERSONAL LOGISTICS: slot changed → fulfill that slot (per-player)
script.on_event(defines.events.on_entity_logistic_slot_changed, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()

  if storage.facc_gui_state.switches["facc_instant_request"] and instant_request.on_entity_logistic_slot_changed then
    safe_call("instant_request.on_entity_logistic_slot_changed", instant_request.on_entity_logistic_slot_changed, e)
  end
  -- Always safe; module will early-exit if player disabled
  if instant_trash.on_entity_logistic_slot_changed then
    safe_call("instant_trash.on_entity_logistic_slot_changed", instant_trash.on_entity_logistic_slot_changed, e)
  end
end)

-- PERSONAL LOGISTICS: inventory changes → resync and/or purge per-player
script.on_event(defines.events.on_player_main_inventory_changed, function(e)
  ensure_state()

  if storage.facc_gui_state.switches["facc_instant_request"] and instant_request.on_player_main_inventory_changed then
    safe_call("instant_request.on_player_main_inventory_changed", instant_request.on_player_main_inventory_changed, e)
  end
  if instant_trash.on_player_main_inventory_changed then
    safe_call("instant_trash.on_player_main_inventory_changed", instant_trash.on_player_main_inventory_changed, e)
  end
end)

-- Ammo inventory changes → also drive instant trash
script.on_event(defines.events.on_player_ammo_inventory_changed, function(e)
  ensure_state()
  if instant_trash.on_player_ammo_inventory_changed then
    safe_call("instant_trash.on_player_ammo_inventory_changed", instant_trash.on_player_ammo_inventory_changed, e)
  end
end)

-- Cursor stack changes → also drive instant trash
script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
  ensure_state()
  if instant_trash.on_player_cursor_stack_changed then
    safe_call("instant_trash.on_player_cursor_stack_changed", instant_trash.on_player_cursor_stack_changed, e)
  end
end)

-- GUI closed → process the entity if supported (for instant purge after manual changes)
script.on_event(defines.events.on_gui_closed, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  local ent = e.entity
  if ent and ent.valid and instant_trash.on_entity_logistic_slot_changed then
    safe_call("instant_trash.on_entity_logistic_slot_changed", instant_trash.on_entity_logistic_slot_changed, {entity = ent})
  end
end)
