-- scripts/events/build_events.lua
-- Single event dispatcher: registers each Factorio event exactly once and
-- forwards to per-feature modules. Tested on 2.0.60 (stable) and 2.0.66+.
--
-- Goals:
--  * Avoid handler overwrites (Factorio keeps only the last script.on_event per event)
--  * Keep all per-feature logic inside their modules; this file is the glue.
--  * Always read e.entity/e.created_entity safely, as event payloads differ.

local instant_bp_build = require("scripts/blueprints/instant_blueprint_building")
local instant_rail     = require("scripts/blueprints/instant_rail_planner")
local instant_decon    = require("scripts/blueprints/instant_deconstruction")
local instant_upgrade  = require("scripts/blueprints/instant_upgrading")
local clean_pollution  = require("scripts/environment/clean_pollution")
local instant_research = require("scripts/cheats/instant_research")
local instant_request  = require("scripts/logistic-network/instant_request")
local instant_trash    = require("scripts/logistic-network/instant_trash")

-- Minimal persistent GUI state scaffold (mirrors what GUI code expects)
local function ensure_state()
  storage.facc_gui_state = storage.facc_gui_state or { sliders = {}, switches = {}, is_open = false }
  storage.facc_gui_state.switches = storage.facc_gui_state.switches or {}
end

-- Permission gate (best-effort):
local function allowed(player_index)
  local p = player_index and game.get_player(player_index) or nil
  if not p then return false end
  if _G.is_allowed then return is_allowed(p) end
  return true
end

--------------------------------------------------------------------------------
-- Player-built entities: blueprint/rail fast paths
--------------------------------------------------------------------------------
script.on_event(defines.events.on_built_entity, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()

  local ent = e.entity or e.created_entity
  if not (ent and ent.valid) then return end

  -- Blueprint building pipeline:
  if ent.type == "entity-ghost" or ent.type == "tile-ghost" or ent.type == "item-request-proxy" then
    if storage.facc_gui_state.switches["facc_instant_blueprint_building"] then
      instant_bp_build.on_built_entity(e)
      return
    end

    if ent.type == "entity-ghost" and storage.facc_gui_state.switches["facc_instant_rail_planner"] then
      instant_rail.on_built_entity(e)
      return
    end
  end
end)

-- Robot/script built (no-op for instant_trash; kept for symmetry/future use)
script.on_event(
  {defines.events.on_robot_built_entity, defines.events.script_raised_built},
  function(e)
    ensure_state()
    if instant_trash.on_entity_created then
      instant_trash.on_entity_created(e)
    end
  end
)

-- Removals (death/mined/script) (no-op for instant_trash; kept for symmetry/future use)
script.on_event(
  {defines.events.on_entity_died, defines.events.on_robot_mined_entity, defines.events.on_player_mined_entity, defines.events.script_raised_destroy},
  function(e)
    ensure_state()
    if instant_trash.on_entity_removed then
      instant_trash.on_entity_removed(e)
    end
  end
)

--------------------------------------------------------------------------------
-- Marked for deconstruction: instant removal (entities) → processed on tick
--------------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_deconstruction, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if storage.facc_gui_state.switches["facc_instant_deconstruction"] then
    instant_decon.on_marked_for_deconstruction(e)
  end
end)

--------------------------------------------------------------------------------
-- Player deconstruction selection (tiles) → module decides tile handling
--------------------------------------------------------------------------------
script.on_event(defines.events.on_player_deconstructed_area, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if storage.facc_gui_state.switches["facc_instant_deconstruction"] then
    instant_decon.on_player_deconstructed_area(e)
  end
end)

--------------------------------------------------------------------------------
-- Marked for upgrade: instant upgrade
--------------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_upgrade, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if storage.facc_gui_state.switches["facc_instant_upgrading"] then
    instant_upgrade.on_marked_for_upgrade(e)
  end
end)

--------------------------------------------------------------------------------
-- On-tick: central worker hub (ONLY this file registers on_tick)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_tick, function(event)
  ensure_state()
  local s = storage.facc_gui_state

  -- 1) Instant Blueprint Building worker
  if s.switches["facc_instant_blueprint_building"] and instant_bp_build.on_tick then
    instant_bp_build.on_tick(event)
  end

  -- 2) Instant Deconstruction queue
  if s.switches["facc_instant_deconstruction"] and instant_decon.on_tick then
    instant_decon.on_tick(event)
  end

  -- 3) Existing automations
  if s.switches["facc_auto_clean_pollution"] then
    local secs = s.sliders["slider_auto_clean_pollution"] or 60
    if secs >= 1 and (event.tick % (secs * 60) == 0) then
      for _,p in pairs(game.players) do clean_pollution.run(p) end
    end
  end
  if s.switches["facc_auto_instant_research"] then
    local secs = s.sliders["slider_auto_instant_research"] or 1
    if secs >= 1 and (event.tick % (secs * 60) == 0) then
      for _,p in pairs(game.players) do instant_research.run(p) end
    end
  end

  -- 4) Instant Request per-player worker (gated by GUI switch)
  if s.switches["facc_instant_request"] and instant_request.on_tick then
    instant_request.on_tick(event)
  end

  -- 5) Instant Trash worker (ALWAYS safe to call; module checks per-player toggles)
  if instant_trash.on_tick then
    instant_trash.on_tick(event)
  end
end)

-- PERSONAL LOGISTICS: slot changed → fulfill that slot (per-player)
script.on_event(defines.events.on_entity_logistic_slot_changed, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()

  if storage.facc_gui_state.switches["facc_instant_request"] and instant_request.on_entity_logistic_slot_changed then
    instant_request.on_entity_logistic_slot_changed(e)
  end
  -- Always safe; module will early-exit if player disabled
  if instant_trash.on_entity_logistic_slot_changed then
    instant_trash.on_entity_logistic_slot_changed(e)
  end
end)

-- PERSONAL LOGISTICS: inventory changes → resync and/or purge per-player
script.on_event(defines.events.on_player_main_inventory_changed, function(e)
  ensure_state()

  if storage.facc_gui_state.switches["facc_instant_request"] and instant_request.on_player_main_inventory_changed then
    instant_request.on_player_main_inventory_changed(e)
  end
  if instant_trash.on_player_main_inventory_changed then
    instant_trash.on_player_main_inventory_changed(e)
  end
end)

-- Ammo inventory changes → also drive instant trash
script.on_event(defines.events.on_player_ammo_inventory_changed, function(e)
  ensure_state()
  if instant_trash.on_player_ammo_inventory_changed then
    instant_trash.on_player_ammo_inventory_changed(e)
  end
end)

-- Cursor stack changes → also drive instant trash
script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
  ensure_state()
  if instant_trash.on_player_cursor_stack_changed then
    instant_trash.on_player_cursor_stack_changed(e)
  end
end)
