-- scripts/blueprints/build_all_ghosts.lua
-- Build All Ghosts

local M = {}
local flib_table = require("__flib__.table")

-- Insert helper that preserves item quality if provided.
local function insert_with_quality(container, name, count, quality)
  local stack = { name = name, count = count }
  if quality ~= nil then stack.quality = quality end
  local ok, inserted = pcall(function() return container.insert(stack) end)
  if ok and tonumber(inserted) then return inserted else return 0 end
end

-- Insert requested items into the proxy target.
-- Modules go to the module inventory first, then normal insert, then common inventories.
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
    local quality = r.quality  -- present only when Quality DLC is active / non-normal

    if name and left > 0 then
      -- 1) Module inventory (if present)
      local ok_mod, mod_inv = pcall(function()
        return target.get_module_inventory and target.get_module_inventory()
      end)
      if ok_mod and mod_inv then
        left = left - insert_with_quality(mod_inv, name, left, quality)
      end

      -- 2) Direct insert into the entity
      if left > 0 then
        left = left - insert_with_quality(target, name, left, quality)
      end

      -- 3) Common inventories (ammo, fuel, trunk)
      if left > 0 and target.get_inventory then
        local ok_def, inv_def = pcall(function() return defines.inventory end)
        local function try_inv(id)
          local ok1, inv = pcall(function() return target.get_inventory(id) end)
          if ok1 and inv then
            left = left - insert_with_quality(inv, name, left, quality)
          end
        end
        if ok_def and inv_def then
          if left > 0 and inv_def.turret_ammo then try_inv(inv_def.turret_ammo) end
          if left > 0 and inv_def.fuel       then try_inv(inv_def.fuel)       end
          if left > 0 and inv_def.car_trunk  then try_inv(inv_def.car_trunk)  end
        end
      end

      if left > 0 then
        all_done = false -- keep proxy so the remainder stays visible
      end
    end
  end

  if all_done then
    proxy.destroy()
  end
end

-- Fulfill every proxy on the surface (button is a one-shot, so scanning all is fine).
local function fulfill_all_proxies(surface)
  local ok, proxies = pcall(function()
    return surface.find_entities_filtered{ type = "item-request-proxy" }
  end)
  if not (ok and proxies) then return end
  flib_table.for_each(proxies, function(p)
    fulfill_item_request_proxy(p)
  end)
end

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface
  local force = player.force

  -- 1) Revive entity ghosts
  flib_table.for_each(surface.find_entities_filtered{ force = force, type = "entity-ghost" }, function(ghost)
    if ghost.valid then
      pcall(function() ghost.revive() end) -- proxy may be created with quality-aware requests
    end
  end)

  -- 2) Revive tile ghosts (including landfill)
  local tiles_to_set = {}
  flib_table.for_each(surface.find_entities_filtered{ type = "tile-ghost" }, function(tile)
    if tile.valid then
      if tile.ghost_name == "landfill" then
        pcall(function() tile.revive() end)
      else
        table.insert(tiles_to_set, { name = tile.ghost_name, position = tile.position })
      end
    end
  end)
  if #tiles_to_set > 0 then
    pcall(function() surface.set_tiles(tiles_to_set) end)
  end

  -- 3) Fulfill item requests (modules first, preserving quality)
  fulfill_all_proxies(surface)

  -- Keep the original short message key only
  player.print({"facc.build-all-ghosts-msg"})
end

return M
