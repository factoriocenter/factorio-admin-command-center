-- scripts/power/recharge_energy.lua
-- Event-driven recharge of force entities and equipment grids.

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_recharge_energy"
local CHUNKS_PER_TICK = 5
local STATUS_OPTIONS = {
  process_name = {"facc.recharge-energy"}
}

local function recharge_grid(grid)
  if not grid then
    return
  end
  flib_table.for_each(grid.equipment, function(eq)
    if eq.valid and eq.energy and eq.max_energy then
      eq.energy = eq.max_energy
    end
  end)
end

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  if chunk_jobs.has_active_job_for_player(JOBS_KEY, player.index) then
    return
  end

  chunk_jobs.enqueue_job(JOBS_KEY, {
    player_index = player.index,
    force_name = player.force.name,
    surface_indices = chunk_jobs.collect_single_surface_indices(player.surface),
    surface_cursor = 1,
    chunks = nil,
    chunk_cursor = 1
  })

  if not chunk_jobs.is_background_optimization_enabled(player.index) then
    M.on_tick({ tick = game.tick })
  end
end

function M.on_tick(_event)
  chunk_jobs.run_jobs(
    JOBS_KEY,
    CHUNKS_PER_TICK,
    function(job, surface, _chunk, area)
      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        force = job.force_name
      }, function(entity)
        if not entity.valid then
          return
        end
        if entity.energy and entity.electric_buffer_size then
          entity.energy = entity.electric_buffer_size
        end
        if entity.grid then
          recharge_grid(entity.grid)
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({"facc.recharge-energy-msg"})
      end
    end,
    STATUS_OPTIONS
  )
end

return M
