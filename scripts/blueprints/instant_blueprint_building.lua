-- scripts/blueprints/instant_blueprint_building.lua
-- Instant Blueprint Building

local M = {}
local flib_bounding_box = require("__flib__.bounding-box")
local flib_queue = require("__flib__.queue")

-- Persistent queue keys
local PENDING_PROXY_KEY   = "facc_pending_item_proxies"
local PENDING_AREA_KEY    = "facc_pending_revive_areas"

-- Space Age platform foundation tile
local FOUNDATION_NAME     = "space-platform-foundation"

-- Tunables
local REVIVE_PAD          = 3.0     -- expand around ghost bbox
local MAX_REVIVE_TRIES    = 240     -- total ticks to try reviving an area (~4s)
local TILE_WARMUP_TRIES   = 18      -- first N tries: tiles-only on space platforms

--------------------------------------------------------------------------------
-- Storage helpers
--------------------------------------------------------------------------------
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

local function ensure_queue(key)
  local value = storage[key]
  if value == nil then
    value = flib_queue.new()
    storage[key] = value
    return value
  end

  if is_queue(value) then
    return value
  end

  if type(value) == "table" then
    local converted = array_to_queue(value)
    storage[key] = converted
    return converted
  end

  local fallback = flib_queue.new()
  storage[key] = fallback
  return fallback
end

local function ensure_storage()
  ensure_queue(PENDING_PROXY_KEY)
  ensure_queue(PENDING_AREA_KEY)
end

--------------------------------------------------------------------------------
-- Geometry helpers
--------------------------------------------------------------------------------
--- Returns a copy of 'area' expanded by 'pad' on all sides.
-- @param area table  bounding box ({left_top=.., right_bottom=..} or 2-point)
-- @param pad  number padding value
local function expand_area(area, pad)
  pad = pad or 0
  local explicit = flib_bounding_box.ensure_explicit(area)
  return flib_bounding_box.resize(explicit, pad)
end

--- Builds a safe bbox for an entity (ghost or real). Falls back to a 1×1 around position.
-- @param ent LuaEntity
-- @return table|nil
local function bbox_from_entity_safe(ent)
  if not (ent and ent.valid) then return nil end
  local ok, bb = pcall(function() return ent.bounding_box end)
  if ok and bb then return bb end
  local okp, p = pcall(function() return ent.position end)
  if okp and p then
    return flib_bounding_box.from_position(p, false)
  end
  return nil
end

--------------------------------------------------------------------------------
-- Revive helpers
--------------------------------------------------------------------------------
--- Try to revive a tile ghost. Returns true if the tile ghost no longer exists.
local function try_revive_tile_ghost(g)
  if not (g and g.valid and g.type == "tile-ghost") then return false end
  local ok = pcall(function() g.revive() end)
  return ok and (not (g.valid and g.type == "tile-ghost"))
end

--- Try to revive an entity ghost. Returns true if the entity ghost no longer exists.
local function try_revive_entity_ghost(g)
  if not (g and g.valid and g.type == "entity-ghost") then return false end
  pcall(function() g.revive{ raise_revive = true } end)
  return not (g.valid and g.type == "entity-ghost")
end

--- Revive ALL tile ghosts in the area (foundation first, then others).
-- @return number revived_count
local function revive_all_tiles(surface, area)
  if not (surface and area) then return 0 end
  local revived = 0

  -- 1) Foundation tiles
  local ok1, tg1 = pcall(function()
    return surface.find_entities_filtered{ area = area, type = "tile-ghost" }
  end)
  if ok1 and tg1 then
    for _, g in pairs(tg1) do
      if g.valid and g.ghost_name == FOUNDATION_NAME then
        if try_revive_tile_ghost(g) then revived = revived + 1 end
      end
    end
  end

  -- 2) Any remaining tile ghosts (non-foundation)
  local ok2, tg2 = pcall(function()
    return surface.find_entities_filtered{ area = area, type = "tile-ghost" }
  end)
  if ok2 and tg2 then
    for _, g in pairs(tg2) do
      if g.valid and g.ghost_name ~= FOUNDATION_NAME then
        if try_revive_tile_ghost(g) then revived = revived + 1 end
      end
    end
  end

  return revived
end

--- Revive ALL entity ghosts in the area.
-- @return number revived_count, number remaining_count
local function revive_all_entities(surface, area)
  if not (surface and area) then return 0, 0 end
  local revived, remaining = 0, 0
  local ok, list = pcall(function()
    return surface.find_entities_filtered{ area = area, type = "entity-ghost" }
  end)
  if not (ok and list) then return revived, remaining end

  for _, g in pairs(list) do
    if g.valid then
      if try_revive_entity_ghost(g) then
        revived = revived + 1
      else
        remaining = remaining + 1
      end
    end
  end
  return revived, remaining
end

--------------------------------------------------------------------------------
-- Item-request proxy (modules first) — QUALITY-AWARE
--------------------------------------------------------------------------------
--- Fulfill a single item-request proxy. Modules go to module inventory first.
-- Preserves item quality if Quality DLC is active.
-- Returns true if fully fulfilled (proxy destroyed or empty).
local function fulfill_item_request_proxy(proxy)
  if not (proxy and proxy.valid and proxy.type == "item-request-proxy") then
    return true
  end

  local target = proxy.proxy_target
  if not (target and target.valid) then
    proxy.destroy()
    return true
  end

  local reqs = proxy.item_requests or {}
  local remaining = {}
  local all_ok = true

  for _, r in pairs(reqs) do
    local name = r.name
    local need = tonumber(r.count) or 0
    if name and need > 0 then
      local left = need

      -- Extract quality if present. It may be a string or a table with .name.
      local q = r.quality
      if type(q) == "table" and q.name then q = q.name end

      -- Helper to build an insert stack that includes quality only when present.
      local function stack(cnt)
        local s = { name = name, count = cnt }
        if q ~= nil then s.quality = q end
        return s
      end

      -- 1) Module inventory first
      local ok_mod, mod_inv = pcall(function()
        return target.get_module_inventory and target.get_module_inventory()
      end)
      if ok_mod and mod_inv and left > 0 then
        local ok_ins, ins = pcall(function() return mod_inv.insert(stack(left)) end)
        if ok_ins and tonumber(ins) then left = left - ins end
      end

      -- 2) Direct insert into entity
      if left > 0 then
        local ok_ins, ins = pcall(function() return target.insert(stack(left)) end)
        if ok_ins and tonumber(ins) then left = left - ins end
      end

      -- 3) Try common inventories (ammo, fuel, trunk)
      if left > 0 and target.get_inventory then
        local function try_inv(id)
          local ok1, inv = pcall(function() return target.get_inventory(id) end)
        if ok1 and inv then
            local ok2, ins = pcall(function() return inv.insert(stack(left)) end)
            if ok2 and tonumber(ins) then left = left - ins end
          end
        end
        local ok_def, inv_def = pcall(function() return defines.inventory end)
        if ok_def and inv_def then
          if left > 0 and inv_def.turret_ammo then try_inv(inv_def.turret_ammo) end
          if left > 0 and inv_def.fuel       then try_inv(inv_def.fuel)       end
          if left > 0 and inv_def.car_trunk  then try_inv(inv_def.car_trunk)  end
        end
      end

      if left > 0 then
        all_ok = false
        table.insert(remaining, { name = name, count = left, quality = q })
      end
    end
  end

  if all_ok then
    proxy.destroy()
    return true
  else
    proxy.item_requests = remaining
    return false
  end
end

--- Fulfill every item-request proxy inside area (or around entity bbox).
local function fulfill_nearby_proxies(surface, area_or_entity)
  if not surface then return end
  local area = area_or_entity
  if area_or_entity and area_or_entity.valid then
    area = bbox_from_entity_safe(area_or_entity)
  end
  if not area then return end

  local ok, proxies = pcall(function()
    return surface.find_entities_filtered{ area = area, type = "item-request-proxy" }
  end)
  if not (ok and proxies) then return end

  for _, proxy in pairs(proxies) do
    fulfill_item_request_proxy(proxy)
  end
end

--------------------------------------------------------------------------------
-- Queue management
--------------------------------------------------------------------------------
--- Enqueue an area to be processed on tick with a warm-up for tiles on space platforms.
local function enqueue_area(surface, area)
  local queue = ensure_queue(PENDING_AREA_KEY)
  local explicit = flib_bounding_box.ensure_explicit(area)
  flib_queue.push_back(queue, {
    surface_index = surface.index,
    area = explicit,
    tries = 0
  })
end

--------------------------------------------------------------------------------
-- Event handler (player built ghost / tile ghost / item proxy)
--------------------------------------------------------------------------------
--- Main entry: called when a ghost (tile/entity) or an item-request-proxy appears.
-- Caches needed fields and schedules an area-wide multi-pass job.
function M.on_built_entity(event)
  local ent = event.entity or event.created_entity
  if not (ent and ent.valid) then return end

  ensure_storage()

  local ok_type, ent_type = pcall(function() return ent.type end)
  if not ok_type then return end

  -- Immediate path for fresh item-request-proxy: try to fulfill now and also queue a short retry window
  if ent_type == "item-request-proxy" then
    local surface_ok, surface = pcall(function() return ent.surface end)
    if surface_ok and surface then
      local bb = bbox_from_entity_safe(ent)
      local area = bb and expand_area(bb, REVIVE_PAD) or nil
      fulfill_item_request_proxy(ent)
      if area then
        flib_queue.push_back(ensure_queue(PENDING_PROXY_KEY), { surface_index = surface.index, area = area, tries = 0 })
      end
    end
    return
  end

  -- Only ghosts reach here
  if ent_type ~= "tile-ghost" and ent_type ~= "entity-ghost" then
    return
  end

  local ok_s, surface = pcall(function() return ent.surface end)
  if not (ok_s and surface) then return end

  local bb = bbox_from_entity_safe(ent)
  if not bb then return end
  local area = expand_area(bb, REVIVE_PAD)

  -- Quick path for tile ghost: try immediately; if it's foundation, it unblocks entities.
  if ent_type == "tile-ghost" then
    local is_foundation = false
    local ok_gn, gn = pcall(function() return ent.ghost_name end)
    if ok_gn and gn == FOUNDATION_NAME then is_foundation = true end
    try_revive_tile_ghost(ent)
    if is_foundation then
      -- Small local sweep to kickstart nearby entities/proxies
      revive_all_entities(surface, area)
      fulfill_nearby_proxies(surface, area)
    end
  end

  -- Always enqueue the area for the multi-pass tick worker (covers entities & tiles)
  enqueue_area(surface, area)

  -- Also create a short proxy retry window
  flib_queue.push_back(ensure_queue(PENDING_PROXY_KEY), { surface_index = surface.index, area = area, tries = 0 })
end

--------------------------------------------------------------------------------
-- Tick worker: multi-pass converging loop (EXPORTED)
--------------------------------------------------------------------------------
function M.on_tick(_event)
  local Qa = storage and ensure_queue(PENDING_AREA_KEY)
  if Qa and flib_queue.length(Qa) > 0 then
    local jobs_to_process = flib_queue.length(Qa)
    for _ = 1, jobs_to_process do
      local job = flib_queue.pop_front(Qa)
      if job then
        local keep_job = false
        local surface = game.surfaces[job.surface_index]
        if surface then
          job.tries = (job.tries or 0) + 1

          local area = job.area
          local is_space_platform = (surface.platform ~= nil)

          -- Phase A: Tiles only (warm-up) on space platforms.
          if is_space_platform and job.tries <= TILE_WARMUP_TRIES then
            revive_all_tiles(surface, area)
            keep_job = true
          else
            -- Full pass: Tiles (foundation first), then Entities, then Proxies
            revive_all_tiles(surface, area)
            local _, remaining = revive_all_entities(surface, area)
            fulfill_nearby_proxies(surface, area)

            -- Keep trying while entity ghosts remain and we still have budget.
            if remaining > 0 and job.tries < MAX_REVIVE_TRIES then
              keep_job = true
            end
          end
        end

        if keep_job then
          flib_queue.push_back(Qa, job)
        end
      end
    end
  end

  -- Short proxy retry queue
  local Qp = storage and ensure_queue(PENDING_PROXY_KEY)
  if Qp and flib_queue.length(Qp) > 0 then
    local proxies_to_process = flib_queue.length(Qp)
    for _ = 1, proxies_to_process do
      local e = flib_queue.pop_front(Qp)
      if e then
        local surface = game.surfaces[e.surface_index]
        if surface then
          fulfill_nearby_proxies(surface, e.area)
          e.tries = (e.tries or 0) + 1
          if e.tries < 10 then
            flib_queue.push_back(Qp, e)
          end
        end
      end
    end
  end
end

return M
