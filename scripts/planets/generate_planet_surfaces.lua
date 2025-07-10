-- scripts/planets/generate_planet_surfaces.lua
-- Gera todas as superfícies dos planetas e mapeia uma área de 150×150 centrada em (0,0).

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local half = 75
  for _, planet in pairs(game.planets) do
    local surface = planet.create_surface()
    game.forces["player"].chart(surface, {{-half, -half}, {half, half}})
  end

  player.print({"facc.generate-planet-surfaces-msg"})
end

return M
