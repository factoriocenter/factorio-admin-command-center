-- scripts/character/create_legendary_armor.lua
-- Generates a full mech armor with legendary-quality equipment in all grid slots

local M = {}

-- Permission check: single-player or admin in multiplayer
local function is_allowed(player)
  return player and (not game.is_multiplayer() or player.admin)
end

--- Inserts a fully-equipped legendary mech armor into the first free inventory slot.
-- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- equipment layout: {equipment_name, grid_x, grid_y}
  local layout = {
    {"fission-reactor-equipment", 0, 0}, {"fission-reactor-equipment", 4, 0},
    {"fission-reactor-equipment", 0, 4}, {"fission-reactor-equipment", 4, 4},
    {"personal-laser-defense-equipment", 6, 0}, {"personal-laser-defense-equipment", 8, 0},
    {"personal-laser-defense-equipment", 10, 0}, {"personal-laser-defense-equipment", 12, 0},
    {"personal-laser-defense-equipment", 8, 2}, {"personal-laser-defense-equipment", 10, 2},
    {"personal-laser-defense-equipment", 12, 2}, {"personal-laser-defense-equipment", 12, 4},
    {"exoskeleton-equipment", 8, 4}, {"exoskeleton-equipment", 10, 4},
    {"exoskeleton-equipment", 0, 8}, {"exoskeleton-equipment", 2, 8},
    {"exoskeleton-equipment", 4, 8}, {"exoskeleton-equipment", 6, 8},
    {"exoskeleton-equipment", 8, 8}, {"exoskeleton-equipment", 10, 8},
    {"exoskeleton-equipment", 12, 8}, {"night-vision-equipment", 12, 6},
    {"battery-mk3-equipment", 14, 0}, {"battery-mk3-equipment", 14, 2},
    {"battery-mk3-equipment", 14, 4}, {"battery-mk3-equipment", 14, 6},
    {"battery-mk3-equipment", 14, 8}, {"battery-mk3-equipment", 14, 10},
    {"battery-mk3-equipment", 14, 12}, {"belt-immunity-equipment", 14, 14},
    {"belt-immunity-equipment", 14, 15}, {"toolbelt-equipment", 0, 16},
    {"toolbelt-equipment", 3, 16}, {"toolbelt-equipment", 6, 16},
    {"toolbelt-equipment", 9, 16}, {"toolbelt-equipment", 12, 16},
    {"energy-shield-mk2-equipment", 0, 14}, {"energy-shield-mk2-equipment", 2, 14},
    {"energy-shield-mk2-equipment", 4, 14}, {"energy-shield-mk2-equipment", 6, 14},
    {"energy-shield-mk2-equipment", 8, 14}, {"energy-shield-mk2-equipment", 10, 14},
    {"personal-roboport-mk2-equipment", 0, 12}, {"personal-roboport-mk2-equipment", 2, 12},
    {"personal-roboport-mk2-equipment", 4, 12}, {"personal-roboport-mk2-equipment", 6, 12},
    {"personal-roboport-mk2-equipment", 8, 12}, {"personal-roboport-mk2-equipment", 10, 12},
    {"personal-roboport-mk2-equipment", 12, 12}, {"personal-roboport-mk2-equipment", 14, 16},
    {"personal-roboport-mk2-equipment", 12, 14}
  }

  -- Helper: place all equipment into the grid
  local function apply_layout(grid)
    for _, e in ipairs(layout) do
      grid.put{name = e[1], position = {e[2], e[3]}, quality = "legendary"}
    end
  end

  -- Attempt to insert the armor into the first empty slot
  local inv = player.get_main_inventory()
  local inserted = false

  for i = 1, #inv do
    if not inv[i].valid_for_read then
      inv[i].set_stack{name = "mech-armor", count = 1, quality = "legendary"}
      apply_layout(inv[i].grid)
      inserted = true
      break
    end
  end

  if inserted then
    player.print({"facc.create-legendary-armor-success"})
  else
    player.print({"facc.create-legendary-armor-failure"})
  end
end

return M
