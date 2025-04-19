-- scripts/map/remove_deconstruction_marks.lua
-- This module deletes all entities on the surface that are marked for deconstruction.
-- Useful for clearing pending removal tasks in bulk.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local surface = player.surface

  for _, entity in pairs(surface.find_entities_filtered{to_be_deconstructed = true}) do
    if entity.valid then
      entity.destroy()
    end
  end

  player.print({"facc.remove-decon-msg"})
end

return M
