-- scripts/character/invincible_player.lua
-- Switch: toggles player character invincibility (character.destructible).
-- Per-player persistence + safe reapply on join/respawn.
-- All comments and docs in English as requested.

local M = {}

--- Internal storage helper (per-player boolean map).
-- @return table
local function store()
  storage.facc_invincible_player = storage.facc_invincible_player or {}
  return storage.facc_invincible_player
end

--- Reapply the saved state for a player, if any.
-- Does not perform permission checks; used on join/respawn.
-- @param player LuaPlayer
function M.apply_saved(player)
  if not (player and player.valid) then return end
  local s = store()
  local enable = s[player.index]
  if type(enable) == "boolean" and player.character and player.character.valid then
    player.character.destructible = not enable
  end
end

--- Toggle invincibility for the invoking player.
-- Checks admin/singleplayer permission via global guard `is_allowed`.
-- Saves the state and applies immediately if character exists.
-- @param player  LuaPlayer
-- @param enable  boolean  true = invincible; false = normal
function M.run(player, enable)
  -- Permission: allow in single-player or admins in multiplayer
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local s = store()
  s[player.index] = enable

  -- Apply if a character body is present; otherwise print contextual hint.
  if player.character and player.character.valid then
    player.character.destructible = not enable
    if enable then
      player.print({"facc.invincible-player-activated"})
    else
      player.print({"facc.invincible-player-deactivated"})
    end
    return
  end

  -- No character: inform according to controller type (ghost vs. god/editor).
  if player.controller_type == defines.controllers.ghost then
    player.print({"facc.invincible-player-cannot-before-respawn"})
  else
    player.print({"facc.invincible-player-cannot-in-god"})
  end
end

return M
