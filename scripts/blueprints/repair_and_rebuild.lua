-- scripts/blueprints/repair_and_rebuild.lua
-- Instantly repairs all damaged entities and revives all ghosts for the player's force.
-- After reviving, fulfills any item-request proxies (modules first), preserving item quality
-- when the Quality DLC is active.

local M = {}
local item_request_proxy = require("scripts/utils/item_request_proxy")
local flib_table = require("scripts/utils/flib_table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")

local JOBS_KEY_HEALTH = "facc_jobs_repair_rebuild_health"
local JOBS_KEY_ENTITY_GHOSTS = "facc_jobs_repair_rebuild_entity_ghosts"
local JOBS_KEY_TILE_GHOSTS = "facc_jobs_repair_rebuild_tile_ghosts"
local JOBS_KEY_PROXIES = "facc_jobs_repair_rebuild_proxies"
local CHUNKS_PER_TICK = 5
local STATUS_CHAIN = {
  process_name = {"facc.repair-rebuild"},
  progress_milestones = {25, 50, 75},
  completion_progress_enabled = false
}
local STATUS_FINAL = {
  process_name = {"facc.repair-rebuild"},
  progress_milestones = {25, 50, 75}
}

local function has_active_job(player_index)
  return chunk_jobs.has_active_job_for_player(JOBS_KEY_HEALTH, player_index)
    or chunk_jobs.has_active_job_for_player(JOBS_KEY_ENTITY_GHOSTS, player_index)
    or chunk_jobs.has_active_job_for_player(JOBS_KEY_TILE_GHOSTS, player_index)
    or chunk_jobs.has_active_job_for_player(JOBS_KEY_PROXIES, player_index)
end

-- Shared fulfillment respects blueprint slots, equipment grids, and quality.
local function fulfill_item_request_proxy(proxy)
  return item_request_proxy.fulfill(proxy)
end

function M.run(player)
  -- Permission: allow in singleplayer or if admin in multiplayer
  if not (not game.is_multiplayer() or player.admin) then
    player.print({"facc.not-allowed"})
    return
  end

  if has_active_job(player.index) then
    return
  end

  chunk_jobs.enqueue_job(JOBS_KEY_HEALTH, {
    player_index = player.index,
    force_name = player.force.name,
    surface_index = player.surface.index,
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
    JOBS_KEY_HEALTH,
    CHUNKS_PER_TICK,
    function(job, surface, _chunk, area)
      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        force = job.force_name
      }, function(ent)
        if ent.valid and ent.health then
          pcall(function() ent.health = 1e9 end)
        end
      end)
    end,
    function(job)
      chunk_jobs.enqueue_job(JOBS_KEY_ENTITY_GHOSTS, {
        player_index = job.player_index,
        force_name = job.force_name,
        surface_index = job.surface_index,
        surface_indices = { job.surface_index },
        surface_cursor = 1,
        chunks = nil,
        chunk_cursor = 1,
        progress_started = job.progress_started,
        progress_next_milestone_index = job.progress_next_milestone_index
      })
    end,
    STATUS_CHAIN
  )

  chunk_jobs.run_jobs(
    JOBS_KEY_ENTITY_GHOSTS,
    CHUNKS_PER_TICK,
    function(job, surface, _chunk, area)
      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        force = job.force_name,
        type = "entity-ghost"
      }, function(ghost)
        if ghost.valid then
          pcall(function() ghost.revive() end)
        end
      end)
    end,
    function(job)
      chunk_jobs.enqueue_job(JOBS_KEY_TILE_GHOSTS, {
        player_index = job.player_index,
        force_name = job.force_name,
        surface_index = job.surface_index,
        surface_indices = { job.surface_index },
        surface_cursor = 1,
        chunks = nil,
        chunk_cursor = 1,
        progress_started = job.progress_started,
        progress_next_milestone_index = job.progress_next_milestone_index
      })
    end,
    STATUS_CHAIN
  )

  chunk_jobs.run_jobs(
    JOBS_KEY_TILE_GHOSTS,
    CHUNKS_PER_TICK,
    function(job, surface, _chunk, area)
      local tiles_to_set = {}
      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        force = job.force_name,
        type = "tile-ghost"
      }, function(tile)
        if not tile.valid then
          return
        end
        if tile.ghost_name == "landfill" then
          pcall(function() tile.revive() end)
        else
          tiles_to_set[#tiles_to_set + 1] = { name = tile.ghost_name, position = tile.position }
        end
      end)
      if #tiles_to_set > 0 then
        pcall(function() surface.set_tiles(tiles_to_set) end)
      end
    end,
    function(job)
      chunk_jobs.enqueue_job(JOBS_KEY_PROXIES, {
        player_index = job.player_index,
        surface_indices = { job.surface_index },
        surface_cursor = 1,
        chunks = nil,
        chunk_cursor = 1,
        progress_started = job.progress_started,
        progress_next_milestone_index = job.progress_next_milestone_index
      })
    end,
    STATUS_CHAIN
  )

  chunk_jobs.run_jobs(
    JOBS_KEY_PROXIES,
    CHUNKS_PER_TICK,
    function(_job, surface, _chunk, area)
      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        type = "item-request-proxy"
      }, function(proxy)
        fulfill_item_request_proxy(proxy)
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({"facc.repair-rebuild-msg"})
      end
    end,
    STATUS_FINAL
  )
end

return M
