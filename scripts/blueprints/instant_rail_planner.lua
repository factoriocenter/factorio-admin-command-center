-- scripts/blueprints/instant_rail_planner.lua
-- Instantly revives rail ghosts only (straight/curved rail).

local M = {}
local RAIL_GHOSTS = {
  ["straight-rail"] = true,
  ["curved-rail"] = true,
  ["curved-rail-a"] = true,
  ["curved-rail-b"] = true,
  ["legacy-curved-rail"] = true,
  ["legacy-straight-rail"] = true,
  ["half-diagonal-rail"] = true,
  ["elevated-curved-rail-a"] = true,
  ["elevated-curved-rail-b"] = true,
  ["elevated-half-diagonal-rail"] = true,
  ["elevated-straight-rail"] = true,
  ["bridge-curved-rail-a"] = true,
  ["bridge-curved-rail-b"] = true,
  ["bridge-straight-rail"] = true,
  ["rail-ramp"] = true,
  ["rail-support"] = true,
}

function M.on_built_entity(event)
  local g = event.entity or event.created_entity
  if not (g and g.valid and g.type == "entity-ghost") then return end

  local name = g.ghost_name
  if name and RAIL_GHOSTS[name] then
    pcall(function() g.revive{ raise_revive = true } end)
  end
end

return M
