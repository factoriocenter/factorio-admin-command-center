-- scripts/utils/chunk_job_runner.lua
-- Shared chunk-based job runner for heavy map-wide operations.

local M = {}
local flib_table = require("__flib__.table")
local BACKGROUND_OPTIMIZATION_SETTING = "facc-enable-background-optimization"

local function get_jobs(storage_key)
  return flib_table.get_or_insert(storage, storage_key, {})
end

local function clamp(value, min_value, max_value)
  if value < min_value then return min_value end
  if value > max_value then return max_value end
  return value
end

local function copy_options(options)
  local copied = {}
  if options then
    for key, value in pairs(options) do
      copied[key] = value
    end
  end
  return copied
end

local function read_global_background_optimization_setting()
  local setting = settings and settings.global and settings.global[BACKGROUND_OPTIMIZATION_SETTING]
  if setting ~= nil then
    return setting.value == true
  end
  return nil
end

function M.is_background_optimization_enabled(player_index)
  local global_value = read_global_background_optimization_setting()
  if global_value ~= nil then
    return global_value
  end

  -- Backwards-compatibility for older saves where this setting was runtime-per-user.
  if player_index and settings and settings.get_player_settings then
    local ok, player_settings = pcall(settings.get_player_settings, player_index)
    if ok and player_settings then
      local player_setting = player_settings[BACKGROUND_OPTIMIZATION_SETTING]
      if player_setting ~= nil then
        return player_setting.value == true
      end
    end
  end
  return false
end

function M.make_chunk_area(chunk)
  local x = chunk.x * 32
  local y = chunk.y * 32
  return { { x, y }, { x + 32, y + 32 } }
end

function M.collect_surface_chunks(surface)
  local chunks = {}
  for chunk in surface.get_chunks() do
    chunks[#chunks + 1] = { x = chunk.x, y = chunk.y }
  end
  return chunks
end

function M.collect_all_surface_indices()
  local surface_indices = {}
  flib_table.for_each(game.surfaces, function(surface)
    if surface and surface.valid then
      surface_indices[#surface_indices + 1] = surface.index
    end
  end)
  return surface_indices
end

function M.collect_single_surface_indices(surface)
  if surface and surface.valid then
    return { surface.index }
  end
  return {}
end

local function ensure_surface_chunks(job)
  if job.chunks then
    return true
  end

  local surface_index = job.surface_indices[job.surface_cursor]
  if not surface_index then
    return false
  end

  local surface = game.surfaces[surface_index]
  if not (surface and surface.valid) then
    job.surface_cursor = job.surface_cursor + 1
    return ensure_surface_chunks(job)
  end

  job.chunks = M.collect_surface_chunks(surface)
  job.chunk_cursor = 1
  return true
end

local function advance_surface(job)
  job.surface_cursor = job.surface_cursor + 1
  job.chunks = nil
  job.chunk_cursor = 1
end

function M.has_active_job_for_player(storage_key, player_index)
  local jobs = get_jobs(storage_key)
  for _, job in ipairs(jobs) do
    if job.player_index == player_index then
      return true
    end
  end
  return false
end

function M.enqueue_job(storage_key, job)
  if not job.created_tick then
    job.created_tick = game.tick
  end
  local jobs = get_jobs(storage_key)
  jobs[#jobs + 1] = job
end

function M.remove_jobs_for_player(storage_key, player_index)
  local jobs = get_jobs(storage_key)
  local i = 1
  while i <= #jobs do
    if jobs[i].player_index == player_index then
      table.remove(jobs, i)
    else
      i = i + 1
    end
  end
end

local function get_active_chunk_jobs_count()
  local cache_tick = storage.facc_chunk_jobs_count_tick
  if cache_tick == game.tick then
    return storage.facc_chunk_jobs_count_value or 0
  end

  local total = 0
  for key, value in pairs(storage) do
    if type(key) == "string" and key:find("^facc_jobs_") and type(value) == "table" then
      total = total + #value
    end
  end

  storage.facc_chunk_jobs_count_tick = game.tick
  storage.facc_chunk_jobs_count_value = total
  return total
end

local function resolve_chunks_per_tick(base_chunks, options)
  local base = math.max(1, math.floor(tonumber(base_chunks) or 1))
  if options and options.adaptive == false then
    return base
  end

  -- Heuristic throttle:
  -- fewer active jobs -> process more chunks per tick;
  -- many active jobs  -> process fewer chunks per tick.
  local active_jobs = get_active_chunk_jobs_count()
  local delta = 0
  if active_jobs <= 2 then
    delta = 2
  elseif active_jobs <= 4 then
    delta = 1
  elseif active_jobs <= 8 then
    delta = 0
  elseif active_jobs <= 12 then
    delta = -1
  else
    delta = -2
  end

  local min_chunks = options and options.min_chunks_per_tick or 1
  local max_chunks = options and options.max_chunks_per_tick or (base * 3)
  return clamp(base + delta, min_chunks, math.max(min_chunks, max_chunks))
end

local function compute_progress_percent(job)
  local total_surfaces = #job.surface_indices
  if total_surfaces <= 0 then
    return 100
  end

  local completed_surfaces = math.max((job.surface_cursor or 1) - 1, 0)
  local current_surface_progress = 0
  if job.chunks and #job.chunks > 0 then
    local processed_current_surface_chunks = math.max((job.chunk_cursor or 1) - 1, 0)
    current_surface_progress = processed_current_surface_chunks / #job.chunks
  end

  local percent = math.floor(((completed_surfaces + current_surface_progress) / total_surfaces) * 100)
  percent = clamp(percent, 0, 99)

  -- Keep monotonic progress for UX even when surface sizes differ a lot.
  if job.progress_last_percent and percent < job.progress_last_percent then
    percent = job.progress_last_percent
  end
  job.progress_last_percent = percent
  return percent
end

local function get_process_name(options)
  if options and options.process_name then
    return options.process_name
  end
  return {"facc.main-title"}
end

local function print_started_if_needed(job, options)
  if job.progress_started then
    return
  end
  if options and options.started_enabled == false then
    return
  end
  if options and options.progress_enabled == false then
    return
  end

  local player = game.get_player(job.player_index)
  if not (player and player.valid) then
    return
  end

  local started_key = options and options.started_message_key or "facc.background-job-started-named"
  player.print({ started_key, get_process_name(options) })
  job.progress_started = true
  job.progress_next_milestone_index = 1
end

local function print_progress_if_needed(job, options)
  if not job.progress_started then
    return
  end
  if options and options.progress_enabled == false then
    return
  end

  local player = game.get_player(job.player_index)
  if not (player and player.valid) then
    return
  end

  local percent = compute_progress_percent(job)
  local milestones = options and options.progress_milestones or {25, 50, 75}
  local idx = job.progress_next_milestone_index or 1
  local progress_key = options and options.progress_message_key or "facc.background-job-progress-named"

  while idx <= #milestones and percent >= milestones[idx] do
    player.print({ progress_key, get_process_name(options), milestones[idx] })
    idx = idx + 1
  end

  job.progress_next_milestone_index = idx
end

local function print_completed_if_needed(job, options)
  if not job.progress_started then
    return
  end
  if options and options.completion_progress_enabled == false then
    return
  end
  if options and options.progress_enabled == false then
    return
  end
  local player = game.get_player(job.player_index)
  if not (player and player.valid) then
    return
  end

  local progress_key = options and options.progress_message_key or "facc.background-job-progress-named"
  player.print({ progress_key, get_process_name(options), 100 })
end

function M.run_jobs(storage_key, chunks_per_tick, process_chunk, on_job_done, options)
  local jobs = get_jobs(storage_key)
  local i = 1

  while i <= #jobs do
    local job = jobs[i]
    local effective_options = copy_options(options)
    local background_enabled = M.is_background_optimization_enabled(job.player_index)
    if not background_enabled then
      effective_options.adaptive = false
      effective_options.progress_enabled = false
      effective_options.started_enabled = false
      effective_options.completion_progress_enabled = false
    end

    local per_tick
    if background_enabled then
      per_tick = resolve_chunks_per_tick(chunks_per_tick, effective_options)
    else
      -- Instant mode: emulate legacy behavior and process everything in a single pass.
      per_tick = 2147483647
    end

    local processed_chunks = 0
    local done = false

    while processed_chunks < per_tick do
      if not ensure_surface_chunks(job) then
        done = true
        break
      end

      local surface_index = job.surface_indices[job.surface_cursor]
      local surface = game.surfaces[surface_index]
      local chunk = job.chunks[job.chunk_cursor]
      if not (surface and surface.valid and chunk) then
        advance_surface(job)
        goto continue
      end

      process_chunk(job, surface, chunk, M.make_chunk_area(chunk))

      job.chunk_cursor = job.chunk_cursor + 1
      if job.chunk_cursor > #job.chunks then
        advance_surface(job)
      end

      processed_chunks = processed_chunks + 1
      ::continue::
    end

    if done then
      print_completed_if_needed(job, effective_options)
      if on_job_done then
        on_job_done(job)
      end
      table.remove(jobs, i)
    else
      print_started_if_needed(job, effective_options)
      print_progress_if_needed(job, effective_options)
      i = i + 1
    end
  end
end

return M
