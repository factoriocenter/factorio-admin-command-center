-- scripts/combat/ammo_to_turrets.lua
-- Inserts appropriate ammo into empty turrets:
--   • gun-turret       → uranium-rounds-magazine (100)
--   • artillery-turret → artillery-shell (5)
--   • rocket-turret    → rocket (100) [Space Age only]
--   • railgun-turret   → railgun-ammo (10) [Space Age only]

local M = {}
local flib_table = require("__flib__.table")
local chunk_jobs = require("scripts/utils/chunk_job_runner")
local compat = require("scripts/utils/mod_compat")

-- Detect whether the Space Age DLC/mod is active
local space_age_enabled = compat.is_space_age_stack_active()
local JOBS_KEY = "facc_jobs_ammo_to_turrets"
local CHUNKS_PER_TICK = 8
local STATUS_OPTIONS = {
  process_name = {"facc.ammo-turrets"}
}
local cached_target_turret_names = nil

local function get_target_turret_names()
  if cached_target_turret_names then
    return cached_target_turret_names
  end

  local names = {}
  local function add_if_exists(name)
    if compat.prototype_exists("entity_prototypes", name) then
      names[#names + 1] = name
    end
  end

  add_if_exists("gun-turret")
  add_if_exists("artillery-turret")
  if space_age_enabled then
    add_if_exists("rocket-turret")
    add_if_exists("railgun-turret")
  end

  cached_target_turret_names = names
  return cached_target_turret_names
end

local function get_turret_ammo_inventory(turret)
  if not (turret and turret.valid) then
    return nil
  end

  if turret.name == "artillery-turret" and defines.inventory.artillery_turret_ammo then
    return turret.get_inventory(defines.inventory.artillery_turret_ammo)
  end

  return turret.get_inventory(defines.inventory.turret_ammo)
end

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
    function(job, surface, _chunk, area)
      local target_turret_names = get_target_turret_names()
      if #target_turret_names == 0 then
        return
      end

      flib_table.for_each(surface.find_entities_filtered{
        area = area,
        force = job.force_name,
        name = target_turret_names
      }, function(turret)
        if not turret.valid then
          return
        end

        local ammo_name = nil
        local ammo_count = 0
        if turret.name == "gun-turret" then
          ammo_name = compat.find_first_existing("item_prototypes", {
            "uranium-rounds-magazine",
            "piercing-rounds-magazine",
            "firearm-magazine"
          })
          ammo_count = 100
        elseif turret.name == "artillery-turret" then
          ammo_name, ammo_count = "artillery-shell", 5
        elseif space_age_enabled and turret.name == "rocket-turret" then
          ammo_name = compat.find_first_existing("item_prototypes", {"rocket", "explosive-rocket"})
          ammo_count = 100
        elseif space_age_enabled and turret.name == "railgun-turret" then
          ammo_name, ammo_count = "railgun-ammo", 10
        end

        if ammo_name and compat.prototype_exists("item_prototypes", ammo_name) then
          local inv = get_turret_ammo_inventory(turret)
          if inv and inv.is_empty() then
            pcall(function()
              inv.insert{ name = ammo_name, count = ammo_count }
            end)
          end
        end
      end)
    end,
    function(job)
      local player = game.get_player(job.player_index)
      if player and player.valid then
        player.print({"facc.ammo-turrets-msg"})
      end
    end,
    STATUS_OPTIONS
  )
end

return M
