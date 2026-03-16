-- scripts/mining/non_minable_permanent.lua
-- Event-driven permanent non-minable apply for all surfaces.

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_non_minable_permanent"
local CHUNKS_PER_TICK = 6
local STATUS_OPTIONS = {
  process_name = {"facc.non-minable-permanent"}
}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  chunk_jobs.remove_jobs_for_player(JOBS_KEY, player.index)

  chunk_jobs.enqueue_job(JOBS_KEY, {
    player_index = player.index,
    force_name = player.force.name,
    surface_indices = chunk_jobs.collect_all_surface_indices(),
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
        if entity.valid and entity.minable ~= nil then
          entity.minable = false
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({"facc.minable-disabled-permanent"})
      end
    end,
    STATUS_OPTIONS
  )
end

return M
