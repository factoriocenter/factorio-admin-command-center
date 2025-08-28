-- scripts/blueprints/instant_deconstruction.lua
-- Instantly removes entities when they are marked for deconstruction and,
-- additionally, reverts placed tiles (floors/landfill etc.) immediately when
-- the player uses the Deconstruction Planner to mark an area.
--
-- Entity flow (unchanged):
--   • Prefers proper mining (to return items); falls back to destroy.
--   • Ghosts are simply destroyed.
--
-- Tile flow (new):
--   • Listens to on_player_deconstructed_area and scans the selected area.
--   • For each LuaTile, if a hidden tile exists, we restore it right away.
--     This mirrors what robots would do (reverting floors to the underlying tile).
--   • Safe fallback: if no hidden tile is present, we skip that position.

local M = {}

--------------------------------------------------------------------------------
-- Entities: instant removal on mark-for-deconstruction
--------------------------------------------------------------------------------
--- Handles entity deconstruction marks.
-- @param event EventData.on_marked_for_deconstruction
function M.on_marked_for_deconstruction(event)
  local ent = event.entity
  if not (ent and ent.valid) then return end

  -- Ghosts can simply be destroyed
  if ent.type == "entity-ghost" then
    ent.destroy({ raise_destroy = true })
    return
  end

  -- Prefer mining to recover items
  local player = event.player_index and game.get_player(event.player_index) or nil
  local mined_ok = false

  if player then
    mined_ok = pcall(function()
      return ent.mine({ force = player.force, player = player })
    end) and true or false
  end

  if not mined_ok then
    -- Fallback: destroy (may spill items depending on prototype)
    ent.destroy({ raise_destroy = true })
  end
end

--------------------------------------------------------------------------------
-- Tiles: instant revert on deconstruction selection (area-based)
--------------------------------------------------------------------------------
--- Instantly reverts placed tiles in the player's deconstruction selection area.
-- Uses the tile's hidden tile when available, which replicates the normal
-- deconstruction outcome (e.g., removing concrete back to the previous terrain).
-- @param event EventData.on_player_deconstructed_area
function M.on_player_deconstructed_area(event)
  -- Sanity: require a valid player (permissions are enforced by the dispatcher)
  local player = event.player_index and game.get_player(event.player_index) or nil
  if not player then return end

  -- Resolve surface + area from event
  local surface = (event.surface_index and game.surfaces[event.surface_index]) or player.surface
  local area    = event.area
  if not (surface and area) then return end

  -- Collect tile changes: revert to hidden tile when present
  local changes = {}
  for _, tile in pairs(surface.find_tiles_filtered{ area = area }) do
    -- LuaTile.hidden_tile holds the original tile name replaced by the current one
    local back = tile.hidden_tile
    if back and type(back) == "string" and #back > 0 then
      changes[#changes+1] = { name = back, position = tile.position }
    end
  end

  if #changes > 0 then
    -- Apply in one batch; Factorio handles corrections as needed.
    -- We intentionally don't pass extra flags to keep behavior consistent
    -- with our other tile operations in the mod.
    surface.set_tiles(changes)
  end
end

return M
