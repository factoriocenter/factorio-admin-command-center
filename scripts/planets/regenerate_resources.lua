-- scripts/planets/regenerate_resources.lua
-- Regenerate all finite resource patches on the player's current surface.
-- • Finite resources are destroyed and regenerated via autoplace.
-- • Infinite resources are left untouched.
-- • Finally, mining drills are refreshed to reconnect.

local M = {}

--- Regenerates finite resource entities on the player's current surface.
-- Destroys all finite resources, records their prototype names, and regenerates them.
-- Infinite resources remain unchanged.
-- @param player LuaPlayer The player invoking the command.
function M.run(player)
  if not is_allowed(player) then
    -- Player is not allowed to use this feature
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface

  -- 1) Destroy all finite resources and collect their names for regeneration
  local to_regenerate = {}
  for _, resource in ipairs(surface.find_entities_filtered{type = "resource"}) do
    if not resource.prototype.infinite_resource then
      to_regenerate[resource.name] = true
      resource.destroy()
    end
  end

  -- 2) Regenerate each collected resource type by name
  for resource_name in pairs(to_regenerate) do
    surface.regenerate_entity(resource_name)
  end

  -- 3) Refresh connections on all mining drills
  for _, drill in ipairs(surface.find_entities_filtered{type = "mining-drill"}) do
    drill.update_connections()
  end

  player.print({"facc.regenerate-resources-msg"})
end

return M
