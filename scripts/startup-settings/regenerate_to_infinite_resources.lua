-- scripts/startup-settings/regenerate_to_infinite_resources.lua
-- Module to regenerate every resource patch on a surface and ensure infinite
-- resources are topped up according to multiplier setting.

local M = {}

--- Regenerates and tops up all resource patches on the given surface.
-- @param surface LuaSurface – the surface on which to enforce infinite resources
function M.run_on_surface(surface)
  if not surface or not surface.find_entities_filtered then return end

  -- Determine multiplier from startup setting (e.g., "5x" -> 5)
  local mult_str   = settings.startup["facc-infinite-resources-multiplier"].value or "1x"
  local multiplier = tonumber(mult_str:match("^(%d+)x$")) or 1

  -- 1) Destroy all finite resources and collect their types
  local to_regenerate = {}
  for _, resource in ipairs(surface.find_entities_filtered{ type = "resource" }) do
    if not resource.prototype.infinite_resource then
      to_regenerate[resource.name] = true
      resource.destroy()
    end
  end

  -- 2) Regenerate each collected resource type
  for resource_name in pairs(to_regenerate) do
    surface.regenerate_entity(resource_name)
  end

  -- 3) Top up every spawned patch according to multiplier
  for _, resource in ipairs(surface.find_entities_filtered{ type = "resource" }) do
    local full_amount = resource.prototype.normal_resource_amount
    if full_amount then
      local amt = full_amount * multiplier
      resource.amount         = amt
      resource.initial_amount = amt
    end
  end

  -- 4) Refresh mining drills so they reconnect
  for _, drill in ipairs(surface.find_entities_filtered{ type = "mining-drill" }) do
    drill.update_connections()
  end
end

return M
