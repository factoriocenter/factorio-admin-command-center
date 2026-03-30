-- scripts/transportation/create_full_spidertron.lua
-- Creates a Spidertron with a pre-defined full equipment grid.
-- Uses automatic layout presets:
--   - Space Age stack: advanced preset (15x11)
--   - Base + Quality: quality preset (15x11)
--   - Base only: base preset (10x6)

local M = {}
local compat = require("scripts/utils/mod_compat")

local SPIDERTRON_LAYOUT_SPACE_AGE = {
  -- Top/center core
  { candidates = { "fusion-reactor-equipment", "fission-reactor-equipment" }, x = 0,  y = 0 },

  -- Exoskeleton cluster
  { candidates = { "exoskeleton-equipment" }, x = 4,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 10, y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 12, y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 10, y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 12, y = 4 },

  -- Right battery column
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment" }, x = 14, y = 0 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment" }, x = 14, y = 2 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment" }, x = 14, y = 4 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment" }, x = 14, y = 6 },
  { candidates = { "battery-mk3-equipment", "battery-mk2-equipment" }, x = 14, y = 8 },

  -- Shields + roboports
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 0, y = 4 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 2, y = 4 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 4, y = 4 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 0, y = 6 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 2, y = 6 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 4, y = 6 },

  -- Laser defense line
  { candidates = { "personal-laser-defense-equipment" }, x = 0,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 2,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 4,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 6,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 8,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 10, y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 12, y = 8 },

  -- Bottom utility/toolbelt row
  { candidates = { "toolbelt-equipment" }, x = 0,  y = 10 },
  { candidates = { "toolbelt-equipment" }, x = 3,  y = 10 },
  { candidates = { "toolbelt-equipment" }, x = 6,  y = 10 },
  { candidates = { "toolbelt-equipment" }, x = 9,  y = 10 },
  { candidates = { "toolbelt-equipment" }, x = 12, y = 10 },
}

local SPIDERTRON_LAYOUT_QUALITY_ONLY = {
  -- Top rows
  { candidates = { "fission-reactor-equipment", "fusion-reactor-equipment" }, x = 0,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 4,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 10, y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 12, y = 0 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 14, y = 0 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 14, y = 2 },

  -- Mid rows
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 0, y = 4 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 2, y = 4 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 4, y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 6,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 8,  y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 10, y = 4 },
  { candidates = { "exoskeleton-equipment" }, x = 12, y = 4 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 14, y = 4 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 0, y = 6 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 2, y = 6 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 4, y = 6 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 14, y = 6 },

  -- Laser row
  { candidates = { "personal-laser-defense-equipment" }, x = 0,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 2,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 4,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 6,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 8,  y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 10, y = 8 },
  { candidates = { "personal-laser-defense-equipment" }, x = 12, y = 8 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 14, y = 8 },

  -- Bottom solar row
  { candidates = { "solar-panel-equipment" }, x = 0,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 1,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 2,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 3,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 4,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 5,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 6,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 7,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 8,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 9,  y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 10, y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 11, y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 12, y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 13, y = 10 },
  { candidates = { "solar-panel-equipment" }, x = 14, y = 10 },
}

local SPIDERTRON_LAYOUT_BASE = {
  { candidates = { "fission-reactor-equipment", "fusion-reactor-equipment" }, x = 0, y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 4, y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 6, y = 0 },
  { candidates = { "exoskeleton-equipment" }, x = 8, y = 0 },
  { candidates = { "personal-roboport-mk2-equipment", "personal-roboport-equipment" }, x = 0, y = 4 },
  { candidates = { "energy-shield-mk2-equipment", "energy-shield-equipment" }, x = 2, y = 4 },
  { candidates = { "personal-laser-defense-equipment" }, x = 4, y = 4 },
  { candidates = { "personal-laser-defense-equipment" }, x = 6, y = 4 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 8, y = 4 },
  { candidates = { "battery-mk2-equipment", "battery-equipment", "battery-mk3-equipment" }, x = 9, y = 4 },
}

local function select_layout()
  if compat.is_space_age_stack_active() then
    return SPIDERTRON_LAYOUT_SPACE_AGE
  end
  if compat.is_quality_active() then
    return SPIDERTRON_LAYOUT_QUALITY_ONLY
  end
  return SPIDERTRON_LAYOUT_BASE
end

local function fill_equipment_energy(equipment)
  if not (equipment and equipment.valid) then
    return
  end
  pcall(function()
    local max_energy = equipment.max_energy
    if max_energy and max_energy > 0 then
      equipment.energy = max_energy
    end
  end)
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
      local put_spec = {
        name = equipment_name,
        position = { entry.x, entry.y }
      }
      if quality_name then
        put_spec.quality = quality_name
      end
      local placed = compat.safe_grid_put(grid, put_spec)
      if placed then
        placed_count = placed_count + 1
        fill_equipment_energy(placed)
      end
    end
  end

  return placed_count, expected_count
end

--- Inserts a pre-configured Spidertron into inventory.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local spidertron_name = compat.find_first_existing("item_prototypes", { "spidertron" })
  if not spidertron_name then
    player.print({ "facc.create-full-spidertron-grid-missing" })
    return
  end

  local quality_name = compat.is_quality_active() and "legendary" or nil
  local inv = player.get_main_inventory()
  if not inv then
    player.print({ "facc.create-full-spidertron-failure" })
    return
  end

  for i = 1, #inv do
    local slot = inv[i]
    if not slot.valid_for_read then
      local stack = { name = spidertron_name, count = 1 }
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
          player.print({ "facc.create-full-spidertron-grid-missing" })
          return
        end

        local layout = select_layout()
        local placed, expected = apply_layout(grid, quality_name, layout)
        fill_grid_energy(grid)
        if expected <= 0 then
          player.print({ "facc.create-full-spidertron-grid-missing" })
          return
        end

        if placed < expected then
          player.print({ "facc.create-full-spidertron-partial", placed, expected })
        else
          player.print({ "facc.create-full-spidertron-success" })
        end
        return
      end
    end
  end

  player.print({ "facc.create-full-spidertron-failure" })
end

return M
