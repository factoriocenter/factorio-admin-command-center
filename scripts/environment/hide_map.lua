-- scripts/environment/hide_map.lua
-- This module uncharts all revealed chunks from the player's force perspective,
-- effectively hiding the entire map.

local M = {}
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_hide_map"
local CHUNKS_PER_TICK = 10
local STATUS_OPTIONS = {
  process_name = {"facc.hide-map"}
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
    function(job, surface, chunk, _area)
      local force = game.forces[job.force_name]
      if force and force.valid then
        force.unchart_chunk({ x = chunk.x, y = chunk.y }, surface)
      end
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({"facc.hide-map-msg"})
      end
    end,
    STATUS_OPTIONS
  )
end

return M
