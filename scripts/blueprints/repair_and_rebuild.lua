-- scripts/blueprints/repair_and_rebuild.lua
-- Instantly repairs all damaged entities and revives all ghosts for the player's force.
-- After reviving, fulfills any item-request proxies (modules first), preserving item quality
-- when the Quality DLC is active.

local M = {}

-- Insert helper that preserves item quality if provided.
local function insert_with_quality(container, name, count, quality)
  local stack = { name = name, count = count }
  if quality ~= nil then stack.quality = quality end
  local ok, inserted = pcall(function() return container.insert(stack) end)
  if ok and tonumber(inserted) then
    return inserted
  else
    return 0
  end
end

-- Fulfill one item-request proxy:
-- 1) module inventory (if present), 2) direct entity insert, 3) common inventories.
-- Keeps the proxy if anything is left (so remainder stays visible to the player/robots).
local function fulfill_item_request_proxy(proxy)
  if not (proxy and proxy.valid and proxy.type == "item-request-proxy") then return end

  local target = proxy.proxy_target
  if not (target and target.valid) then
    proxy.destroy() -- orphan proxy
    return
  end

  local reqs = proxy.item_requests or {}
  local all_done = true

  for _, r in pairs(reqs) do
    local name = r.name
    local left = tonumber(r.count) or 0

    -- Quality can be a string or a table with .name depending on source; normalize to string.
    local q = r.quality
    if type(q) == "table" and q.name then q = q.name end

    if name and left > 0 then
      -- 1) Module inventory first
      local ok_mod, mod_inv = pcall(function()
        return target.get_module_inventory and target.get_module_inventory()
      end)
      if ok_mod and mod_inv then
        left = left - insert_with_quality(mod_inv, name, left, q)
      end

      -- 2) Direct insert into entity
      if left > 0 then
        left = left - insert_with_quality(target, name, left, q)
      end

      -- 3) Common inventories (ammo, fuel, trunk)
      if left > 0 and target.get_inventory then
        local function try_inv(id)
          local ok1, inv = pcall(function() return target.get_inventory(id) end)
          if ok1 and inv then
            left = left - insert_with_quality(inv, name, left, q)
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
        all_done = false
      end
    end
  end

  if all_done then
    proxy.destroy()
  end
end

-- Fulfill every proxy on the surface (single-shot button: scanning the whole surface is fine).
local function fulfill_all_proxies(surface)
  local ok, proxies = pcall(function()
    return surface.find_entities_filtered{ type = "item-request-proxy" }
  end)
  if not (ok and proxies) then return end
  for _, p in pairs(proxies) do
    fulfill_item_request_proxy(p)
  end
end

function M.run(player)
  -- Permission: allow in singleplayer or if admin in multiplayer
  if not (not game.is_multiplayer() or player.admin) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force   = player.force

  -- 1) Instantly restore health of every entity belonging to the force
  for _, ent in ipairs(surface.find_entities_filtered{ force = force }) do
    if ent.valid and ent.health then
      -- Big value effectively tops it up; Factorio will clamp to prototype max internally.
      pcall(function() ent.health = 1e9 end)
    end
  end

  -- 2) Revive all entity ghosts (proxies may be created with quality-aware requests)
  for _, ghost in ipairs(surface.find_entities_filtered{ force = force, type = "entity-ghost" }) do
    if ghost.valid then
      pcall(function() ghost.revive() end)
    end
  end

  -- 3) Revive all tile ghosts (including landfill), batching non-landfill tiles
  local tiles_to_set = {}
  for _, tile in ipairs(surface.find_entities_filtered{ force = force, type = "tile-ghost" }) do
    if tile.valid then
      if tile.ghost_name == "landfill" then
        pcall(function() tile.revive() end)
      else
        table.insert(tiles_to_set, { name = tile.ghost_name, position = tile.position })
      end
    end
  end
  if #tiles_to_set > 0 then
    pcall(function() surface.set_tiles(tiles_to_set) end)
  end

  -- 4) Fulfill item requests (modules first, preserving quality)
  fulfill_all_proxies(surface)

  player.print({"facc.repair-rebuild-msg"})
end

return M
