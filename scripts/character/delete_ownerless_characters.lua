-- scripts/character/delete_ownerless_characters.lua
-- Delete Orphaned Characters module: deletes all character entities not controlled by any player.
-- Only available in single-player or for admins in multiplayer.

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_delete_ownerless_characters"
local CHUNKS_PER_TICK = 8
local STATUS_OPTIONS = {
  process_name = {"facc.delete-ownerless"}
}

--- Deletes all orphaned character entities on the player's current surface.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  chunk_jobs.remove_jobs_for_player(JOBS_KEY, player.index)
  chunk_jobs.enqueue_job(JOBS_KEY, {
    player_index = player.index,
    active_character_unit_number = player.character and player.character.unit_number or nil,
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
        type = "character"
      }, function(entity)
        if entity.valid and entity.unit_number ~= job.active_character_unit_number then
          entity.destroy()
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({ "facc.deleted-ownerless-msg" })
      end
    end,
    STATUS_OPTIONS
  )
end

return M
