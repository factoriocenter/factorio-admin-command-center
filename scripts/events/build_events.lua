-- scripts/events/build_events.lua
-- Single dispatcher: registers each Factorio event exactly once and forwards to
-- per-feature modules. Tested on 2.0.60 (stable) and 2.0.65+ (experimental).
-- Always use e.entity or e.created_entity (depending on event source).

local instant_bp_build = require("scripts/blueprints/instant_blueprint_building")
local instant_rail     = require("scripts/blueprints/instant_rail_planner")
local instant_decon    = require("scripts/blueprints/instant_deconstruction")
local instant_upgrade  = require("scripts/blueprints/instant_upgrading")
local clean_pollution  = require("scripts/environment/clean_pollution")
local instant_research = require("scripts/cheats/instant_research")

local function ensure_state()
  storage.facc_gui_state = storage.facc_gui_state or { sliders = {}, switches = {}, is_open = false }
  storage.facc_gui_state.switches = storage.facc_gui_state.switches or {}
end

local function is_on(key)
  ensure_state()
  return storage.facc_gui_state.switches[key] == true
end

local function allowed(player_index)
  local p = player_index and game.get_player(player_index) or nil
  return p and is_allowed(p)
end

--------------------------------------------------------------------------------
-- Player-built entities: electric buffer fill + ghost revival (blueprint/rail)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_built_entity, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()

  local ent = e.entity or e.created_entity
  if not (ent and ent.valid) then return end

  -- Optional: fill electric buffers if you expose a switch for this feature
  if is_on("facc_fill_electric_buffers_on_build") and fill_buffers and fill_buffers.on_built_entity then
    pcall(function() fill_buffers.on_built_entity(e) end)
  end

  -- Blueprint building pipeline:
  -- Includes item-request-proxy so modules/fuel are inserted immediately.
  if ent.type == "entity-ghost" or ent.type == "tile-ghost" or ent.type == "item-request-proxy" then
    if is_on("facc_instant_blueprint_building") then
      instant_bp_build.on_built_entity(e)
      return
    end

    -- If general instant blueprint is OFF but rail-only switch is ON,
    -- allow the rail-only fast revive path for entity-ghosts of rails.
    if ent.type == "entity-ghost" and is_on("facc_instant_rail_planner") then
      instant_rail.on_built_entity(e)
      return
    end
  end
end)

--------------------------------------------------------------------------------
-- Robot-built entities: only electric buffer fill (no player_index on this event)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_robot_built_entity, function(e)
  ensure_state()
  if is_on("facc_fill_electric_buffers_on_build") and fill_buffers and fill_buffers.on_robot_built_entity then
    pcall(function() fill_buffers.on_robot_built_entity(e) end)
  end
end)

--------------------------------------------------------------------------------
-- Marked for deconstruction: instant removal (entities) → processed on tick
--------------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_deconstruction, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if is_on("facc_instant_deconstruction") then
    instant_decon.on_marked_for_deconstruction(e)
  end
end)

--------------------------------------------------------------------------------
-- Player deconstruction selection (tiles) → selection defines whether tiles are allowed
--------------------------------------------------------------------------------
script.on_event(defines.events.on_player_deconstructed_area, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if is_on("facc_instant_deconstruction") then
    instant_decon.on_player_deconstructed_area(e)
  end
end)

--------------------------------------------------------------------------------
-- Marked for upgrade: instant upgrade
--------------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_upgrade, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if is_on("facc_instant_upgrading") then
    instant_upgrade.on_marked_for_upgrade(e)
  end
end)

--------------------------------------------------------------------------------
-- On-tick: central worker hub (ONLY this file registers on_tick)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_tick, function(event)
  ensure_state()
  local s = storage.facc_gui_state

  -- 1) Instant Blueprint Building worker (needs to run every tick)
  if s.switches["facc_instant_blueprint_building"] and instant_bp_build.on_tick then
    instant_bp_build.on_tick(event)
  end

  -- 2) Instant Deconstruction queue (builds-before-tiles is guaranteed inside the module)
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
end)
