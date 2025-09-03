-- scripts/planets/increase_resources.lua
-- This module sets the amount of all resource entities on the surface
-- to the maximum possible value (2^32 - 1).

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface

  for _, resource in pairs(surface.find_entities_filtered{type = "resource"}) do
    if resource.valid and resource.amount then
      resource.amount = 4294967295 -- Max value for 32-bit unsigned integer
    end
  end

  player.print({"facc.increase-resources-msg"})
end

return M
