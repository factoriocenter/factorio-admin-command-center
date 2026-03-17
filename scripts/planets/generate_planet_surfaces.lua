-- scripts/planets/generate_planet_surfaces.lua
-- Gera todas as superfícies dos planetas e mapeia uma área de 150×150 centrada em (0,0).

local M = {}
local flib_table = require("__flib__.table")
local compat = require("scripts/utils/mod_compat")

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  if not compat.is_mod_active("space-age") or not game.planets then
    player.print({"facc.generate-planet-surfaces-no-space-age"})
    return
  end

  local half = 75
  local chart_force = (player and player.valid and player.force and player.force.valid)
    and player.force
    or game.forces["player"]

  flib_table.for_each(game.planets, function(planet)
    if planet and planet.valid then
      local ok, surface = pcall(planet.create_surface, planet)
      if ok and surface and surface.valid and chart_force and chart_force.valid then
        pcall(chart_force.chart, chart_force, surface, {{-half, -half}, {half, half}})
      end
    end
  end)

  player.print({"facc.generate-planet-surfaces-msg"})
end

return M
