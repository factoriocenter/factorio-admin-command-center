-- scripts/planets/regenerate_resources.lua
-- Regenerate all finite resource patches on the player's current surface.
-- • Finite resources are destroyed and regenerated via autoplace.
-- • Infinite resources are left untouched.
-- • Finally, mining drills are refreshed to reconnect.

local M = {}
local flib_table = require("__flib__.table")

--- Regenerates finite resource entities on the player's current surface.
-- Destroys all finite resources, records their prototype names, and regenerates them.
-- Infinite resources remain untouched.
-- @param player LuaPlayer — the player invoking the command
function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface

  -- 1) Destroy all finite resources and collect their names
  local to_regenerate = {}
  flib_table.for_each(surface.find_entities_filtered{ type = "resource" }, function(resource)
    if not resource.prototype.infinite_resource then
      to_regenerate[resource.name] = true
      resource.destroy()
    end
  end)

  -- 2) Attempt to regenerate each collected resource type (pcall skips non-autoplacable)
  for resource_name in pairs(to_regenerate) do
    pcall(function()
      surface.regenerate_entity(resource_name)
    end)
  end

  -- 3) Refresh connections on all mining drills
  flib_table.for_each(surface.find_entities_filtered{ type = "mining-drill" }, function(drill)
    drill.update_connections()
  end)

  player.print({"facc.regenerate-resources-msg"})
end

return M
