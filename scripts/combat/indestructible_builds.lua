-- scripts/combat/indestructible_builds.lua
-- Event-driven toggle for destructibility on current surface.

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_toggle_indestructible"
local CHUNKS_PER_TICK = 7
local STATUS_OPTIONS = {
  process_name = {"facc.indestructible-builds"}
}

--- Apply or remove indestructibility on existing entities.
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  chunk_jobs.remove_jobs_for_player(JOBS_KEY, player.index)

  chunk_jobs.enqueue_job(JOBS_KEY, {
    player_index = player.index,
    enabled = enabled,
    target_destructible = not enabled,
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
        if entity.valid and entity.destructible ~= nil then
          entity.destructible = job.target_destructible
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        if job.enabled then
          player.print({"facc.indestructible-activated"})
        else
          player.print({"facc.indestructible-deactivated"})
        end
      end
    end,
    STATUS_OPTIONS
  )
end

return M
