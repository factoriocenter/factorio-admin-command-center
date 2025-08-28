-- scripts/blueprints/instant_upgrading.lua
-- Instant upgrading (Factorio >= 2.0.65 only, where LuaEntity.apply_upgrade exists).
-- This module exports a single handler that is invoked by build_events.lua
-- when the "facc_instant_upgrading" switch is ON.

local M = {}

--- Handles on_marked_for_upgrade and applies the upgrade immediately.
-- @param event EventData.on_marked_for_upgrade
function M.on_marked_for_upgrade(event)
  local player = event.player_index and game.get_player(event.player_index) or nil
  if not (player and is_allowed(player)) then return end

  -- Read the FACC switch state
  local switches = storage and storage.facc_gui_state and storage.facc_gui_state.switches or nil
  if not (switches and switches["facc_instant_upgrading"]) then return end

  local ent = event.entity
  if not (ent and ent.valid) then return end

  -- 2.0.65+: apply the upgrade immediately; ignore errors if mapping is invalid
  pcall(function() ent.apply_upgrade() end)
end

return M
