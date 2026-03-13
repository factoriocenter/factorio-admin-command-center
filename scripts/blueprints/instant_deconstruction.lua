-- scripts/blueprints/instant_deconstruction.lua
-- Instant Deconstruction


local M = {}
local flib_bounding_box = require("__flib__.bounding-box")
local flib_queue = require("__flib__.queue")
local flib_table = require("__flib__.table")

-- Keys in storage
local QUEUE_KEY = "facc_pending_instant_deconstruction"
local PREF_KEY  = "facc_last_deconstruction_pref"

-- Ensure/return queue
local function is_queue(value)
  return type(value) == "table" and type(value.first) == "number" and type(value.last) == "number"
end

local function array_to_queue(arr)
  local q = flib_queue.new()
  for i = 1, #arr do
    flib_queue.push_back(q, arr[i])
  end
  return q
end

local function ensure_queue()
  local value = storage[QUEUE_KEY]
  if value == nil then
    value = flib_queue.new()
    storage[QUEUE_KEY] = value
    return value
  end

  if is_queue(value) then
    return value
  end

  if type(value) == "table" then
    local converted = array_to_queue(value)
    storage[QUEUE_KEY] = converted
    return converted
  end

  local fallback = flib_queue.new()
  storage[QUEUE_KEY] = fallback
  return fallback
end

-- Ensure/return per-player preferences
local function ensure_prefs()
  return flib_table.get_or_insert(storage, PREF_KEY, {})
end

-- Point-in-rect check for {left_top={x,y}, right_bottom={x,y}}
local function point_in_area(pos, area)
  if not (pos and area) then return false end
  local ok, inside = pcall(function()
    return flib_bounding_box.contains_position(area, pos)
  end)
  return ok and inside or false
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
  flib_queue.push_back(q, { entity = ent, player_index = event.player_index })
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
    local first = event.tiles[1]
    if first and first.position then
      area = {
        left_top = { x = first.position.x, y = first.position.y },
        right_bottom = { x = first.position.x, y = first.position.y }
      }
    end
    for i = 2, #event.tiles do
      local tile = event.tiles[i]
      if tile and tile.position then
        if area then
          area = flib_bounding_box.expand_to_contain_position(area, tile.position)
        else
          area = {
            left_top = { x = tile.position.x, y = tile.position.y },
            right_bottom = { x = tile.position.x, y = tile.position.y }
          }
        end
      end
    end
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
  local q = storage and ensure_queue()
  if not (q and flib_queue.length(q) > 0) then return end

  local new_tiles_on_surfaces = nil

  -- Process one full queue pass (FIFO)
  local jobs = flib_queue.length(q)
  for _ = 1, jobs do
    local data   = flib_queue.pop_front(q)
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
            local bucket = flib_table.get_or_insert(new_tiles_on_surfaces, sname, { tiles = {} })
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
