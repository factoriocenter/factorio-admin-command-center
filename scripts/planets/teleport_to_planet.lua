-- scripts/planets/teleport_to_planet.lua
-- Teleport player to a selected planet surface (Space Age).
-- If the planet surface does not exist yet, it is generated first.

local M = {}
local compat = require("scripts/utils/mod_compat")

local function get_planet_display_name(planet)
  if planet and planet.valid and planet.prototype and planet.prototype.valid then
    return planet.prototype.localised_name
  end
  return planet and planet.name or "unknown"
end

local function get_safe_destination(surface, player)
  local search_name = "character"
  if player and player.character and player.character.valid and player.character.name then
    search_name = player.character.name
  end

  local center = { x = 0, y = 0 }
  local pos = surface.find_non_colliding_position(search_name, center, 256, 1)
  if pos then
    return pos
  end

  pos = surface.find_non_colliding_position("character", center, 256, 1)
  return pos or center
end

function M.run(player, planet_name)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  if type(planet_name) ~= "string" or planet_name == "" then
    player.print({"facc.teleport-to-planet-invalid", tostring(planet_name)})
    return
  end

  local normalized_name = string.lower(planet_name)
  local display_name = normalized_name
  local surface = nil
  local generated_now = false

  if normalized_name == "nauvis" then
    display_name = "Nauvis"
    surface = game.surfaces["nauvis"] or (player.surface and player.surface.valid and player.surface) or nil
  else
    if not compat.is_space_age_stack_active() then
      player.print({"facc.teleport-to-planet-no-space-age"})
      return
    end

    local planet = game.planets and (game.planets[normalized_name] or game.planets[planet_name])
    if not (planet and planet.valid) then
      player.print({"facc.teleport-to-planet-invalid", planet_name})
      return
    end

    display_name = get_planet_display_name(planet)
    surface = planet.surface

    if not (surface and surface.valid) then
      local ok, created_surface = pcall(planet.create_surface, planet)
      if not ok or not (created_surface and created_surface.valid) then
        player.print({"facc.teleport-to-planet-failed", display_name})
        return
      end
      surface = created_surface
      generated_now = true
    end
  end

  if not (surface and surface.valid) then
    player.print({"facc.teleport-to-planet-failed", display_name})
    return
  end

  if generated_now and player.force and player.force.valid then
    local half = 75
    pcall(player.force.chart, player.force, surface, {{-half, -half}, {half, half}})
    player.print({"facc.teleport-to-planet-generated", display_name})
  end

  local destination = get_safe_destination(surface, player)
  local ok_teleport = player.teleport(destination, surface)
  if ok_teleport then
    player.print({"facc.teleport-to-planet-msg", display_name})
  else
    player.print({"facc.teleport-to-planet-failed", display_name})
  end
end

return M
