-- scripts/planets/regenerate_resources.lua
-- Event-driven regeneration of finite resources on current surface.

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY_RESOURCES = "facc_jobs_regen_resources"
local JOBS_KEY_DRILLS = "facc_jobs_regen_drills"
local CHUNKS_PER_TICK_RESOURCES = 5
local CHUNKS_PER_TICK_DRILLS = 6
local STATUS_CHAIN = {
  process_name = {"facc.regenerate-resources"},
  progress_milestones = {25, 50, 75},
  completion_progress_enabled = false
}
local STATUS_FINAL = {
  process_name = {"facc.regenerate-resources"},
  progress_milestones = {25, 50, 75}
}

local function has_active_job(player_index)
  return chunk_jobs.has_active_job_for_player(JOBS_KEY_RESOURCES, player_index)
    or chunk_jobs.has_active_job_for_player(JOBS_KEY_DRILLS, player_index)
end

--- Regenerates finite resource entities on the player's current surface.
-- Work is queued and processed in chunks to avoid freezes on large saves.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  if has_active_job(player.index) then
    return
  end

  chunk_jobs.enqueue_job(JOBS_KEY_RESOURCES, {
    player_index = player.index,
    surface_index = player.surface.index,
    surface_indices = chunk_jobs.collect_single_surface_indices(player.surface),
    surface_cursor = 1,
    chunks = nil,
    chunk_cursor = 1,
    to_regenerate = {}
  })

  if not chunk_jobs.is_background_optimization_enabled(player.index) then
    M.on_tick({ tick = game.tick })
  end
end

function M.on_tick(_event)
  chunk_jobs.run_jobs(
    JOBS_KEY_RESOURCES,
    CHUNKS_PER_TICK_RESOURCES,
    function(job, surface, _chunk, area)
      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        type = "resource"
      }, function(resource)
        if resource.valid and not resource.prototype.infinite_resource then
          job.to_regenerate[resource.name] = true
          resource.destroy()
        end
      end)
    end,
    function(job)
      local surface = game.surfaces[job.surface_index]
      if surface and surface.valid then
        for resource_name in pairs(job.to_regenerate) do
          pcall(function()
            surface.regenerate_entity(resource_name)
          end)
        end
        chunk_jobs.enqueue_job(JOBS_KEY_DRILLS, {
          player_index = job.player_index,
          surface_indices = { job.surface_index },
          surface_cursor = 1,
          chunks = nil,
          chunk_cursor = 1,
          progress_started = job.progress_started,
          progress_next_milestone_index = job.progress_next_milestone_index
        })
      else
        local player = game.get_player(job.player_index)
        if player and player.valid then
          player.print({"facc.regenerate-resources-msg"})
        end
      end
    end,
    STATUS_CHAIN
  )

  chunk_jobs.run_jobs(
    JOBS_KEY_DRILLS,
    CHUNKS_PER_TICK_DRILLS,
    function(_job, surface, _chunk, area)
      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        type = "mining-drill"
      }, function(drill)
        if drill.valid then
          drill.update_connections()
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({"facc.regenerate-resources-msg"})
      end
    end,
    STATUS_FINAL
  )
end

return M
