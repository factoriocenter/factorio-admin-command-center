-- scripts/transportation/create_full_tank.lua
-- Creates a Tank item with a fixed pre-equipped grid loadout.
-- Uses automatic layout presets:
--   - Space Age stack: advanced preset (11x13)
--   - Base + Quality: quality preset (11x13)
--   - Base only: base preset (6x8)
-- Uses legendary quality when Quality is active.

local M = {}
local compat = require("scripts/utils/mod_compat")

local TANK_LAYOUT_SPACE_AGE = {
  -- Row 0
  { candidates = { "fusion-reactor-equipment", "fission-reactor-equipment" }, x = 0,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 4,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 0 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment", "battery-equipment" }, x = 10, y = 0 },

  -- Row 2
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment", "battery-equipment" }, x = 10, y = 2 },

  -- Row 4
  { candidates = { "exoskeleton-equipment" }, x = 0,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 2,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 4,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 4 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment", "battery-equipment" }, x = 10, y = 4 },

  -- Row 6
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment", "battery-equipment" }, x = 10, y = 6 },

  -- Row 8
  { candidates = { "personal-laser-defense-equipment" }, x = 0,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 2,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 4,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 6,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 8,  y = 8 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment", "battery-equipment" }, x = 10, y = 8 },

  -- Row 10
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 0,  y = 10 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 2,  y = 10 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 4,  y = 10 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 6,  y = 10 },
  { candidates = { "personal-laser-defense-equipment" }, x = 8,  y = 10 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment", "battery-equipment" }, x = 10, y = 10 },

  -- Row 12
  { candidates = { "toolbelt-equipment" }, x = 0,  y = 12 },
  { candidates = { "toolbelt-equipment" }, x = 3,  y = 12 },
  { candidates = { "toolbelt-equipment" }, x = 6,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 9,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 10, y = 12 },
}

local TANK_LAYOUT_QUALITY_ONLY = {
  -- Row 0
  { candidates = { "fission-reactor-equipment", "fusion-reactor-equipment" }, x = 0,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 4,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 0 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 10, y = 0 },

  -- Row 2
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 10, y = 2 },

  -- Row 4
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 0,  y = 4 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 2,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 4,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 4 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 10, y = 4 },

  -- Row 6
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 0,  y = 6 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 2,  y = 6 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 10, y = 6 },

  -- Row 8
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 0,  y = 8 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 2,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 4,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 6,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 8,  y = 8 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 10, y = 8 },

  -- Row 10
  { candidates = { "personal-laser-defense-equipment" }, x = 0,  y = 10 },
  { candidates = { "personal-laser-defense-equipment" }, x = 2,  y = 10 },
  { candidates = { "personal-laser-defense-equipment" }, x = 4,  y = 10 },
  { candidates = { "personal-laser-defense-equipment" }, x = 6,  y = 10 },
  { candidates = { "personal-laser-defense-equipment" }, x = 8,  y = 10 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 10, y = 10 },

  -- Row 12
  { candidates = { "solar-panel-equipment" }, x = 0,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 1,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 2,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 3,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 4,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 5,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 6,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 7,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 8,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 9,  y = 12 },
  { candidates = { "solar-panel-equipment" }, x = 10, y = 12 },
}

local TANK_LAYOUT_BASE = {
  { candidates = { "fission-reactor-equipment", "fusion-reactor-equipment" }, x = 0, y = 0 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 4, y = 0 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 5, y = 0 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 4, y = 2 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 5, y = 2 },
  { candidates = { "exoskeleton-equipment" }, x = 0, y = 4 },
  { candidates = { "personal-laser-defense-equipment" }, x = 2, y = 4 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 4, y = 4 },
  { candidates = { "personal-laser-defense-equipment" }, x = 2, y = 6 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 4, y = 6 },
}

local function select_layout()
  if compat.is_space_age_stack_active() then
    return TANK_LAYOUT_SPACE_AGE
  end
  if compat.is_quality_active() then
    return TANK_LAYOUT_QUALITY_ONLY
  end
  return TANK_LAYOUT_BASE
end

local function fill_equipment_energy(equipment)
  if not (equipment and equipment.valid) then
    return
  end

  local applied = false
  local ok_max, max_energy = pcall(function()
    return equipment.max_energy
  end)

  if ok_max and max_energy and max_energy > 0 then
    local ok_set = pcall(function()
      equipment.energy = max_energy
    end)
    applied = ok_set == true
  end

  -- Fallback for equipment that reports energy differently in some API/mod contexts.
  if not applied then
    pcall(function()
      equipment.energy = 1e30
    end)
  end
end

local function fill_grid_energy(grid)
  if not (grid and grid.valid) then
    return
  end
  for _, eq in pairs(grid.equipment) do
    fill_equipment_energy(eq)
  end
end

local function apply_layout(grid, quality_name, layout)
  if not (grid and grid.valid) then
    return 0, 0
  end

  local placed_count = 0
  local expected_count = 0

  for _, entry in ipairs(layout) do
    local equipment_name = compat.find_first_existing("equipment_prototypes", entry.candidates)
    if equipment_name then
      expected_count = expected_count + 1
      local spec = {
        name = equipment_name,
        position = { entry.x, entry.y }
      }
      if quality_name then
        spec.quality = quality_name
      end
      local placed = compat.safe_grid_put(grid, spec)
      if placed then
        placed_count = placed_count + 1
        fill_equipment_energy(placed)
      end
    end
  end

  fill_grid_energy(grid)
  return placed_count, expected_count
end

--- Inserts a pre-configured Tank into the first free inventory slot.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local tank_name = compat.find_first_existing("item_prototypes", { "tank" })
  if not tank_name then
    player.print({ "facc.create-full-tank-grid-missing" })
    return
  end

  local quality_name = compat.is_quality_active() and "legendary" or nil
  local inv = player.get_main_inventory()
  if not inv then
    player.print({ "facc.create-full-tank-failure" })
    return
  end

  for i = 1, #inv do
    local slot = inv[i]
    if not slot.valid_for_read then
      local stack = { name = tank_name, count = 1 }
      if quality_name then
        stack.quality = quality_name
      end

      if compat.safe_set_stack(slot, stack) then
        local grid = slot.grid
        if not grid then
          local ok, created_grid = pcall(function()
            return slot.create_grid()
          end)
          if ok then
            grid = created_grid
          end
        end

        if not (grid and grid.valid) then
          player.print({ "facc.create-full-tank-grid-missing" })
          return
        end

        local layout = select_layout()
        local placed, expected = apply_layout(grid, quality_name, layout)
        if expected <= 0 then
          player.print({ "facc.create-full-tank-grid-missing" })
          return
        end

        if placed < expected then
          player.print({ "facc.create-full-tank-partial", placed, expected })
        else
          player.print({ "facc.create-full-tank-success" })
        end
        return
      end
    end
  end

  player.print({ "facc.create-full-tank-failure" })
end

return M
