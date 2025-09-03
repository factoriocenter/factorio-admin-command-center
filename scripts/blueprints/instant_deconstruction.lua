-- scripts/blueprints/instant_deconstruction.lua
-- Instant Deconstruction with "entities before tiles" priority.
--
-- Rules:
-- • If the player's selection contains ANY entity ("build"), DO NOT touch tiles.
-- • If the selection contains tiles only, then restore those tiles (hidden_tile).
--
-- How it works:
-- • on_player_deconstructed_area: records the selection preference (allow_tiles).
-- • on_marked_for_deconstruction: for each deconstructible-tile-proxy, checks
--   the player's most recent selection preference; if allow_tiles=false, it
--   CANCELS the proxy (unmarks the tile) and leaves the floor untouched; if true,
--   it queues the tile for restoration.
-- • A worker on on_tick processes the queue: destroys entities and restores
--   allowed tiles in batches (set_tiles(..., true, true, true, true)).

local M = {}

-- Keys in storage
local QUEUE_KEY = "facc_pending_instant_deconstruction"
local PREF_KEY  = "facc_last_deconstruction_pref"

-- Ensure/return queue
local function ensure_queue()
  storage[QUEUE_KEY] = storage[QUEUE_KEY] or {}
  return storage[QUEUE_KEY]
end

-- Ensure/return per-player preferences
local function ensure_prefs()
  storage[PREF_KEY] = storage[PREF_KEY] or {}
  return storage[PREF_KEY]
end

-- Point-in-rect check for {left_top={x,y}, right_bottom={x,y}}
local function point_in_area(pos, area)
  if not (pos and area and area.left_top and area.right_bottom) then return false end
  local x, y = pos.x or pos[1], pos.y or pos[2]
  return x >= area.left_top.x and x <= area.right_bottom.x
     and y >= area.left_top.y and y <= area.right_bottom.y
end

--------------------------------------------------------------------------------
-- Marking: enqueue entity OR cancel tile proxy according to preference
--------------------------------------------------------------------------------
--- @param event EventData.on_marked_for_deconstruction
function M.on_marked_for_deconstruction(event)
  local ent = event.entity
  if not (ent and ent.valid) then return end

  -- If it's a tile proxy, consult the player's most recent selection preference
  if ent.type == "deconstructible-tile-proxy" then
    local prefs = ensure_prefs()
    local pidx  = event.player_index
    local pref  = (pidx and prefs[pidx]) or nil

    local allow_tiles = true
    if pref
       and pref.surface_index == ent.surface.index
       and pref.area
       and point_in_area(ent.position, pref.area)
       and (game.tick - pref.tick) <= 10 -- tiny window to match the selection
    then
      allow_tiles = pref.allow_tiles
    end

    if not allow_tiles then
      -- Selection contained entities → cancel tile deconstruction (keep floor)
      pcall(function() ent.destroy() end)
      return
    end
    -- Otherwise, let it proceed to the queue (we'll restore the floor)
  end

  -- Enqueue (regular entities and "allowed" tiles)
  local q = ensure_queue()
  q[#q+1] = { entity = ent, player_index = event.player_index }
end

--------------------------------------------------------------------------------
-- Area selection: ONLY records preference (does not touch tiles here)
--------------------------------------------------------------------------------
--- @param event EventData.on_player_deconstructed_area
function M.on_player_deconstructed_area(event)
  local player  = event.player_index and game.get_player(event.player_index) or nil
  if not player then return end

  local surface = (event.surface_index and game.surfaces[event.surface_index]) or player.surface
  if not surface then return end

  -- Detect if the selection contains ANY "real" entity
  local has_builds = false
  if event.entities and #event.entities > 0 then
    for _, e in ipairs(event.entities) do
      if e and e.valid and e.type ~= "deconstructible-tile-proxy" then
        has_builds = true
        break
      end
    end
  end

  -- Build a reliable area (use event.area if available; otherwise derive from tiles)
  local area = event.area
  if (not area) and event.tiles and #event.tiles > 0 then
    local minx, miny = math.huge, math.huge
    local maxx, maxy = -math.huge, -math.huge
    for _, t in ipairs(event.tiles) do
      local p = t.position
      if p.x < minx then minx = p.x end
      if p.y < miny then miny = p.y end
      if p.x > maxx then maxx = p.x end
      if p.y > maxy then maxy = p.y end
    end
    area = { left_top = {x=minx, y=miny}, right_bottom = {x=maxx, y=maxy} }
  end

  -- Save the player's selection preference
  local prefs = ensure_prefs()
  prefs[event.player_index] = {
    surface_index = surface.index,
    area          = area,
    allow_tiles   = not has_builds, -- allow tiles ONLY if there are no entities
    tick          = game.tick
  }
end

--------------------------------------------------------------------------------
-- Tick worker: processes the queue (entities + allowed tiles) in batches
--------------------------------------------------------------------------------
function M.on_tick(_)
  local q = storage and storage[QUEUE_KEY]
  if not (q and #q > 0) then return end

  local new_tiles_on_surfaces = nil

  -- Process back-to-front
  for i = #q, 1, -1 do
    local data   = q[i]
    local ent    = data and data.entity

    if ent and ent.valid then
      -- Ensure it's still marked (filtering planners may unmark)
      local marked = false
      local ok, res = pcall(function() return ent.to_be_deconstructed(ent.force) end)
      marked = ok and res or false

      if marked then
        if ent.type == "deconstructible-tile-proxy" then
          local surface = ent.surface
          local pos     = ent.position
          local hidden  = surface and surface.get_hidden_tile and surface.get_hidden_tile(pos)

          if hidden and hidden ~= "" then
            new_tiles_on_surfaces = new_tiles_on_surfaces or {}
            local sname = surface.name
            local bucket = new_tiles_on_surfaces[sname]
            if not bucket then
              bucket = { tiles = {} }
              new_tiles_on_surfaces[sname] = bucket
            end
            bucket.tiles[#bucket.tiles+1] = { name = hidden, position = pos }
          end

          -- Remove the proxy (tile will be applied in batch)
          pcall(function() ent.destroy() end)

        else
          -- Regular entities: destroy (raise script_raised_destroy)
          pcall(function() ent.destroy({ raise_destroy = true }) end)
        end
      end
    end

    table.remove(q, i)
  end

  -- Apply collected tiles per surface
  if new_tiles_on_surfaces then
    for sname, data in pairs(new_tiles_on_surfaces) do
      local surface = game.surfaces[sname]
      if surface and data.tiles and #data.tiles > 0 then
        -- set_tiles(tiles, correct, remove_decoratives, raise_event, apply_projection)
        pcall(function() surface.set_tiles(data.tiles, true, true, true, true) end)
      end
    end
  end
end

return M
