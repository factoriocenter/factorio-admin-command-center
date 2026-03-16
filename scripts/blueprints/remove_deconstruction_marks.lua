-- scripts/blueprints/remove_deconstruction_marks.lua
-- Event-driven removal of deconstruction marks (entities and tiles).

local M = {}
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY = "facc_jobs_remove_deconstruction_marks"
local CHUNKS_PER_TICK = 6
local STATUS_OPTIONS = {
  process_name = {"facc.remove-decon"}
}

--- Execute the "remove all deconstruction marks" operation for the caller.
-- @param player LuaPlayer
function M.run(player)
  -- Only single-player or admins in multiplayer (delegated to your central guard).
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  chunk_jobs.remove_jobs_for_player(JOBS_KEY, player.index)
  chunk_jobs.enqueue_job(JOBS_KEY, {
    player_index = player.index,
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
    function(_job, surface, _chunk, area)
      local ok, marked = pcall(function()
        return surface.find_entities_filtered{
          area = area,
          to_be_deconstructed = true
        }
      end)
      if not (ok and marked) then
        return
      end

      local tiles_to_set = {}
      for _, ent in pairs(marked) do
        if ent and ent.valid then
          if ent.type == "deconstructible-tile-proxy" then
            local pos = ent.position
            local hidden = surface.get_hidden_tile(pos)
            if hidden and hidden ~= "" then
              tiles_to_set[#tiles_to_set + 1] = { name = hidden, position = pos }
            end
            pcall(function() ent.destroy() end)
          else
            pcall(function() ent.destroy({ raise_destroy = true }) end)
          end
        end
      end

      if #tiles_to_set > 0 then
        pcall(function()
          surface.set_tiles(tiles_to_set, true, true, true, true)
        end)
      end
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({"facc.remove-decon-msg"})
      end
    end,
    STATUS_OPTIONS
  )
end

return M
