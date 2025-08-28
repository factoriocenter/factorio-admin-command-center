-- scripts/blueprints/instant_blueprint_building.lua
-- Instantly revives entity and tile ghosts.

local M = {}

function M.on_built_entity(event)
  local ghost = event.entity or event.created_entity
  if not (ghost and ghost.valid) then return end

  if ghost.type == "entity-ghost" then
    pcall(function() ghost.revive{ raise_revive = true } end)
  elseif ghost.type == "tile-ghost" then
    pcall(function() ghost.revive() end)
  end
end

return M
