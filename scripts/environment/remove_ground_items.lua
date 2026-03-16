-- scripts/environment/remove_ground_items.lua
-- Event-driven removal of dropped items across all surfaces.

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_remove_ground_items"
local CHUNKS_PER_TICK = 6
local STATUS_OPTIONS = {
  process_name = {"facc.remove-ground-items"}
}

--- Enqueues dropped-item removal as a background job.
-- @param player LuaPlayer
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
        type = "item-entity"
      }, function(item_entity)
        if item_entity.valid then
          item_entity.destroy()
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({ "facc.remove-ground-items-msg" })
      end
    end,
    STATUS_OPTIONS
  )
end

return M
