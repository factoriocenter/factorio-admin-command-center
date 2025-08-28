-- scripts/events/build_events.lua
-- Single dispatcher: registers events once and forwards to per-feature modules.
-- Works on 2.0.60 (stable) and 2.0.65+ (experimental). Uses e.entity or e.created_entity.

local instant_bp_build = require("scripts/blueprints/instant_blueprint_building")
local instant_rail     = require("scripts/blueprints/instant_rail_planner")
local instant_decon    = require("scripts/blueprints/instant_deconstruction")
local instant_upgrade  = require("scripts/blueprints/instant_upgrading")

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
  if is_on("facc_fill_electric_buffers_on_build") then
    fill_buffers.on_built_entity(e)
  end

  -- Instant blueprint building / rail planner (only acts on ghosts)
  if ent.type == "entity-ghost" or ent.type == "tile-ghost" then
    if is_on("facc_instant_blueprint_building") then
      instant_bp_build.on_built_entity(e)
    elseif is_on("facc_instant_rail_planner") then
      -- Only rails when the general blueprint switch is OFF
      instant_rail.on_built_entity(e)
    end
  end
end)

--------------------------------------------------------------------------------
-- Robot-built entities: only electric buffer fill (no player_index on this event)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_robot_built_entity, function(e)
  ensure_state()
  if is_on("facc_fill_electric_buffers_on_build") then
    fill_buffers.on_robot_built_entity(e)
  end
end)

--------------------------------------------------------------------------------
-- Marked for deconstruction: instant removal (entities)
--------------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_deconstruction, function(e)
  if not allowed(e.player_index) then return end
  ensure_state()
  if is_on("facc_instant_deconstruction") then
    instant_decon.on_marked_for_deconstruction(e)
  end
end)

--------------------------------------------------------------------------------
-- NEW: Player deconstruction selection (tiles) → instant revert
-- We use the area-based event to handle tile deconstruction marks because
-- tiles do not fire on_marked_for_deconstruction like entities do.
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
