-- scripts/planets/generate_planet_surfaces.lua
-- Generates all planet surfaces and charts a 150x150 area around force spawn.

local M = {}
local flib_table = require("__flib__.table")
local flib_area = require("scripts/utils/flib_area")
local compat = require("scripts/utils/mod_compat")

local function get_or_create_surface(planet)
  if planet.surface and planet.surface.valid then
    return planet.surface, false, nil
  end

  local ok, created_surface = pcall(planet.create_surface, planet)
  if not ok then
    return nil, false, tostring(created_surface)
  end

  if created_surface and created_surface.valid then
    return created_surface, true, nil
  end

  if planet.surface and planet.surface.valid then
    return planet.surface, false, nil
  end

  return nil, false, "surface-not-created"
end

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  if not compat.is_space_age_stack_active() or not game.planets then
    player.print({"facc.generate-planet-surfaces-no-space-age"})
    return
  end

  local half = 75
  local chunk_radius = math.ceil(half / 32)
  local chart_force = (player and player.valid and player.force and player.force.valid)
    and player.force
    or game.forces["player"]

  flib_table.for_each(game.planets, function(planet)
    if planet and planet.valid then
      local surface, _created, err = get_or_create_surface(planet)
      if surface and surface.valid and chart_force and chart_force.valid then
        local spawn = chart_force.get_spawn_position(surface) or { x = 0, y = 0 }

        -- Chart both expected centers: force spawn and absolute origin.
        local centers = {
          spawn,
          { x = 0, y = 0 }
        }
        local seen_centers = {}
        flib_table.for_each(centers, function(center)
          local x = tonumber(center and center.x) or 0
          local y = tonumber(center and center.y) or 0
          local key = math.floor(x) .. ":" .. math.floor(y)
          if seen_centers[key] then
            return
          end
          seen_centers[key] = true

          local chart_center = { x = x, y = y }
          local chart_area = flib_area.square_from_center(chart_center, half)

          -- Ensure chunks exist before charting so reveal is immediate and reliable.
          local request_ok, request_err = pcall(function()
            surface.request_to_generate_chunks(chart_center, chunk_radius)
          end)
          if not request_ok then
            log("[FACC] generate_planet_surfaces: request_to_generate_chunks failed for " .. tostring(surface.name) .. ": " .. tostring(request_err))
          end

          local force_gen_ok, force_gen_err = pcall(function()
            surface.force_generate_chunk_requests()
          end)
          if not force_gen_ok then
            log("[FACC] generate_planet_surfaces: force_generate_chunk_requests failed for " .. tostring(surface.name) .. ": " .. tostring(force_gen_err))
          end

          local chart_ok, chart_err = pcall(function()
            chart_force.chart(surface, chart_area)
          end)
          if not chart_ok then
            log("[FACC] generate_planet_surfaces: chart failed for " .. tostring(surface.name) .. ": " .. tostring(chart_err))
          end
        end)

        -- Force chart refresh queue once after both centers.
        local rechart_ok, rechart_err = pcall(function()
          chart_force.rechart(surface)
        end)
        if not rechart_ok then
          log("[FACC] generate_planet_surfaces: rechart failed for " .. tostring(surface.name) .. ": " .. tostring(rechart_err))
        end
      elseif err then
        log("[FACC] generate_planet_surfaces: unable to create surface for " .. tostring(planet.name) .. ": " .. tostring(err))
      end
    end
  end)

  player.print({"facc.generate-planet-surfaces-msg"})
end

return M
