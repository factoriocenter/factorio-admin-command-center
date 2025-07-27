-- scripts/startup-settings/regenerate_to_infinite_resources.lua
-- Regenerate all finite resource patches and top up infinite ones on a surface.

local M = {}

--- Regenerates and tops up all resource patches on the given surface.
-- @param surface LuaSurface — the surface to process
function M.run_on_surface(surface)
  if not (surface and surface.find_entities_filtered) then return end

  -- Determine multiplier from startup setting (e.g., "5x" → 5)
  local mult_str   = settings.startup["facc-infinite-resources-multiplier"].value or "1x"
  local multiplier = tonumber(mult_str:match("^(%d+)x$")) or 1

  -- 1) Destroy all finite resources and collect their names
  local to_regenerate = {}
  for _, resource in ipairs(surface.find_entities_filtered{ type = "resource" }) do
    if not resource.prototype.infinite_resource then
      to_regenerate[resource.name] = true
      resource.destroy()
    end
  end

  -- 2) Attempt to regenerate each collected resource type (pcall skips errors)
  for resource_name in pairs(to_regenerate) do
    pcall(function()
      surface.regenerate_entity(resource_name)
    end)
  end

  -- 3) Top up all remaining resource patches according to multiplier
  for _, resource in ipairs(surface.find_entities_filtered{ type = "resource" }) do
    local normal_amount = resource.prototype.normal_resource_amount
    if normal_amount then
      local amt = normal_amount * multiplier
      resource.amount         = amt
      resource.initial_amount = amt
    end
  end

  -- 4) Refresh connections on all mining drills
  for _, drill in ipairs(surface.find_entities_filtered{ type = "mining-drill" }) do
    drill.update_connections()
  end
end

return M
