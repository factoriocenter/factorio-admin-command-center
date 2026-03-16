-- scripts/mining/toggle_minable.lua
-- Event-driven toggle for minable state on current surface.

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_toggle_minable"
local CHUNKS_PER_TICK = 7
local STATUS_OPTIONS = {
  process_name = {"facc.toggle-minable"}
}

--- Toggles whether entities belonging to the player’s force can be mined.
-- @param player LuaPlayer
-- @param enabled boolean; true → make all non-minable, false → make all minable
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  chunk_jobs.remove_jobs_for_player(JOBS_KEY, player.index)

  chunk_jobs.enqueue_job(JOBS_KEY, {
    player_index = player.index,
    enabled = enabled,
    target_minable = not enabled,
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
        if entity.valid then
          entity.minable = job.target_minable
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        if job.enabled then
          player.print({"facc.minable-disabled"})
        else
          player.print({"facc.minable-enabled"})
        end
      end
    end,
    STATUS_OPTIONS
  )
end

return M
