-- scripts/armor/create_full_armor.lua
-- Generates a fully-equipped armor based on active mods:
-- • Space Age → legendary mech-armor
-- • Quality only → legendary power-armor-mk2
-- • Base only → standard power-armor-mk2

local M = {}

--- Inserts a fully-equipped armor into the first free inventory slot.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Detect mods
  local quality_enabled   = script.active_mods["quality"]    ~= nil
  local space_age_enabled = script.active_mods["space-age"] ~= nil

  -- Choose armor and layout
  local armor_name, armor_quality, layout
  if space_age_enabled then
    armor_name    = "mech-armor"
    armor_quality = "legendary"
    layout = {
      {"fusion-reactor-equipment",    0,  0},
      {"fusion-reactor-equipment",    0,  4},
      {"battery-mk3-equipment",      14,  0},
      {"battery-mk3-equipment",      14,  2},
      {"battery-mk3-equipment",      14,  4},
      {"battery-mk3-equipment",      14,  6},
      {"battery-mk3-equipment",      14,  8},
      {"battery-mk3-equipment",      14, 10},
      {"battery-mk3-equipment",      14, 12},
      {"toolbelt-equipment",          0, 16},
      {"toolbelt-equipment",          3, 16},
      {"toolbelt-equipment",          6, 16},
      {"toolbelt-equipment",          9, 16},
      {"toolbelt-equipment",         12, 16},
      {"exoskeleton-equipment",       0,  8},
      {"exoskeleton-equipment",       2,  8},
      {"exoskeleton-equipment",       4,  8},
      {"exoskeleton-equipment",       6,  8},
      {"exoskeleton-equipment",       8, 12},
      {"exoskeleton-equipment",      10, 12},
      {"exoskeleton-equipment",      12, 12},
      {"exoskeleton-equipment",       0, 12},
      {"exoskeleton-equipment",       2, 12},
      {"exoskeleton-equipment",       4, 12},
      {"exoskeleton-equipment",       6, 12},
      {"exoskeleton-equipment",       8, 12},
      {"exoskeleton-equipment",      10, 12},
      {"exoskeleton-equipment",        8, 8},
      {"energy-shield-mk2-equipment", 8,  0},
      {"energy-shield-mk2-equipment",10,  0},
      {"energy-shield-mk2-equipment", 8,  2},
      {"energy-shield-mk2-equipment",10,  2},
      {"energy-shield-mk2-equipment", 8,  4},
      {"energy-shield-mk2-equipment",10,  4},
      {"energy-shield-mk2-equipment", 8,  6},
      {"energy-shield-mk2-equipment",10,  6},
      {"personal-roboport-mk2-equipment", 4,  0},
      {"personal-roboport-mk2-equipment", 6,  0},
      {"personal-roboport-mk2-equipment", 4,  2},
      {"personal-roboport-mk2-equipment", 6,  2},
      {"personal-roboport-mk2-equipment", 4,  4},
      {"personal-roboport-mk2-equipment", 6,  4},
      {"personal-roboport-mk2-equipment", 4,  6},
      {"personal-roboport-mk2-equipment", 6,  6},
      {"personal-laser-defense-equipment",12,  0},
      {"personal-laser-defense-equipment",12,  2},
      {"personal-laser-defense-equipment",12,  4},
      {"personal-laser-defense-equipment",12,  6},
      {"personal-laser-defense-equipment",10,  8},
      {"personal-laser-defense-equipment",12,  8},
      {"personal-laser-defense-equipment",12, 10},
      {"night-vision-equipment",       10, 10},
      {"belt-immunity-equipment",    14, 14},
      {"belt-immunity-equipment",      14, 15}
    }

  elseif quality_enabled then
    armor_name    = "power-armor-mk2"
    armor_quality = "legendary"
    layout = {
      -- Reactors & Batteries
      {"fission-reactor-equipment",     0,  0},
      {"fission-reactor-equipment",     4,  0},
      {"battery-mk2-equipment",        14,  0},
      {"battery-mk2-equipment",        14,  2},
      {"battery-mk2-equipment",        14,  4},
      {"battery-mk2-equipment",        14,  6},
      {"battery-mk2-equipment",        14,  8},
      {"battery-mk2-equipment",        14, 10},
      {"battery-mk2-equipment",        14, 12},
      -- Shields
      {"energy-shield-mk2-equipment",   0,  4},
      {"energy-shield-mk2-equipment",   2,  4},
      {"energy-shield-mk2-equipment",   4,  4},
      {"energy-shield-mk2-equipment",   6,  4},
      {"energy-shield-mk2-equipment",   0,  6},
      {"energy-shield-mk2-equipment",   2,  6},
      {"energy-shield-mk2-equipment",   4,  6},
      {"energy-shield-mk2-equipment",   6,  6},
      -- Exoskeletons
      {"exoskeleton-equipment",         0, 10},
      {"exoskeleton-equipment",         2, 10},
      {"exoskeleton-equipment",         4, 10},
      {"exoskeleton-equipment",         6, 10},
      {"exoskeleton-equipment",         8, 10},
      {"exoskeleton-equipment",        10, 10},
      {"exoskeleton-equipment",        12, 10},
      -- Lasers
      {"personal-laser-defense-equipment", 8,  0},
      {"personal-laser-defense-equipment",10,  0},
      {"personal-laser-defense-equipment", 8,  2},
      {"personal-laser-defense-equipment",10,  2},
      {"personal-laser-defense-equipment",12,  0},
      {"personal-laser-defense-equipment",12,  2},
      {"personal-laser-defense-equipment",12,  4},
      {"personal-laser-defense-equipment",12,  6},
      {"personal-laser-defense-equipment",10,  8},
      {"personal-laser-defense-equipment",12,  8},
      {"personal-laser-defense-equipment",12,  8},
      {"personal-laser-defense-equipment",12,  6},
      -- Roboports & Vision
      {"personal-roboport-mk2-equipment", 0,  8},
      {"personal-roboport-mk2-equipment", 2,  8},
      {"personal-roboport-mk2-equipment", 4,  8},
      {"personal-roboport-mk2-equipment", 6,  8},
      {"personal-roboport-mk2-equipment", 8,  8},
      {"personal-roboport-mk2-equipment", 8,  4},
      {"personal-roboport-mk2-equipment", 8,  6},
      {"personal-roboport-mk2-equipment",10,  4},
      {"night-vision-equipment",         10,  6},
      -- Belts
      {"belt-immunity-equipment",         0, 14},
      -- Solar panels
      {"solar-panel-equipment",          1, 14},
      {"solar-panel-equipment",          2, 14},
      {"solar-panel-equipment",          3, 14},
      {"solar-panel-equipment",          4, 14},
      {"solar-panel-equipment",          5, 14},
      {"solar-panel-equipment",          6, 14},
      {"solar-panel-equipment",          7, 14},
      {"solar-panel-equipment",          8, 14},
      {"solar-panel-equipment",          9, 14},
      {"solar-panel-equipment",         10, 14},
      {"solar-panel-equipment",         11, 14},
      {"solar-panel-equipment",         12, 14},
      {"solar-panel-equipment",         13, 14},
      {"solar-panel-equipment",         14, 14}
    }

  else
    armor_name    = "power-armor-mk2"
    armor_quality = nil
    layout = {
      {"fission-reactor-equipment",     0,  0},
      {"fission-reactor-equipment",     4,  0},
      {"battery-mk2-equipment",          8,  0},
      {"battery-mk2-equipment",          9,  0},
      {"battery-mk2-equipment",          8,  2},
      {"battery-mk2-equipment",          9,  2},
      {"battery-mk2-equipment",          8,  4},
      {"battery-mk2-equipment",          9,  4},
      {"energy-shield-mk2-equipment",    0,  4},
      {"energy-shield-mk2-equipment",    2,  4},
      {"energy-shield-mk2-equipment",    4,  4},
      {"personal-laser-defense-equipment", 6,  4},
      {"exoskeleton-equipment",           0,  6},
      {"exoskeleton-equipment",           2,  6},
      {"exoskeleton-equipment",           4,  6},
      {"personal-laser-defense-equipment", 6,  6},
      {"night-vision-equipment",          8,  6},
      {"personal-roboport-mk2-equipment", 6,  8},
      {"personal-roboport-mk2-equipment", 8,  8}
    }
  end

  -- Helper: place equipment into the grid
  local function apply_layout(grid)
    for _, e in ipairs(layout) do
      local entry = { name = e[1], position = {e[2], e[3]} }
      if armor_quality then entry.quality = armor_quality end
      grid.put(entry)
    end
  end

  -- Insert armor and apply layout
  local inv = player.get_main_inventory()
  for i = 1, #inv do
    if not inv[i].valid_for_read then
      local stack = { name = armor_name, count = 1 }
      if armor_quality then stack.quality = armor_quality end
      inv[i].set_stack(stack)
      apply_layout(inv[i].grid)
      player.print({"facc.create-full-armor-success"})
      return
    end
  end

  player.print({"facc.create-full-armor-failure"})
end

return M