-- scripts/blueprints/remove_deconstruction_marks.lua
-- Remove Deconstruction Marks (now handles both entities AND tiles).

local M = {}

--- Execute the "remove all deconstruction marks" operation for the caller.
-- @param player LuaPlayer
function M.run(player)
  -- Only single-player or admins in multiplayer (delegated to your central guard).
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  if not surface then
    return
  end

  -- Collect tiles-to-restore in batch.
  local tiles_to_set = {}

  -- Iterate through everything currently marked for deconstruction on this surface.
  -- This returns both regular entities and "deconstructible-tile-proxy".
  local ok, marked = pcall(function()
    return surface.find_entities_filtered{ to_be_deconstructed = true }
  end)
  if not (ok and marked) then
    player.print({"facc.remove-decon-msg"})
    return
  end

  for _, ent in pairs(marked) do
    if ent and ent.valid then
      if ent.type == "deconstructible-tile-proxy" then
        -- Tile removal: restore underlying hidden tile (if any), then remove proxy.
        local pos = ent.position
        local hidden = surface.get_hidden_tile(pos)
        if hidden and hidden ~= "" then
          tiles_to_set[#tiles_to_set+1] = { name = hidden, position = pos }
        end
        -- Remove the proxy regardless (so the mark disappears).
        pcall(function() ent.destroy() end)
      else
        -- Regular entities: destroy them (will raise script_raised_destroy).
        pcall(function() ent.destroy({ raise_destroy = true }) end)
      end
    end
  end

  -- Apply the tile restoration as one batch for performance & consistency.
  if #tiles_to_set > 0 then
    -- set_tiles(tiles, correct_tiles, remove_decoratives, raise_event, apply_projection)
    pcall(function()
      surface.set_tiles(tiles_to_set, true, true, true, true)
    end)
  end

  player.print({"facc.remove-decon-msg"})
end

return M
