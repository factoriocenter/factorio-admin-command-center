-- internal_names.lua
-- When the `facc-internal-names` startup setting is enabled, this script:
--   1. Iterates over specified prototype types (items, recipes, equipment, entities, etc.)
--   2. Constructs a label showing the internal ID, type/subgroup (and for recipes, the primary result)
--   3. Overrides each prototype’s localized_name with the constructed label
--
-- Useful for debugging, localization, or exploring available prototypes.

-- Only run if the startup setting is enabled
local setting = settings.startup["facc-internal-names"]
if not (setting and setting.value) then
  return
end

--------------------------------------------------------------------------------
-- 1) Item names
--------------------------------------------------------------------------------
local item_types = {
  "item", "ammo", "armor", "capsule", "deconstruction-item", "gun",
  "mining-tool", "module", "rail-planner", "repair-tool", "tool",
  "upgrade-item", "item-with-entity-data"
}

for _, t in ipairs(item_types) do
  if data.raw[t] then
    for name, proto in pairs(data.raw[t]) do
      proto.localised_name = proto.name .. " (" .. (proto.subgroup or "nil") .. ")"
    end
  end
end

--------------------------------------------------------------------------------
-- 2) Recipe names (append result)
--------------------------------------------------------------------------------
for name, proto in pairs(data.raw["recipe"] or {}) do
  local result
  local result_name = proto.result or (proto.normal and proto.normal.result) or ""
  -- find the prototype of the result among all item_types
  for _, t in ipairs(item_types) do
    if data.raw[t] and data.raw[t][result_name] then
      result = data.raw[t][result_name]
      break
    end
  end

  if result then
    proto.localised_name = proto.name
      .. " (" .. (proto.subgroup or "nil") .. ") = "
      .. result.name .. " (" .. (result.subgroup or "nil") .. ")"
  else
    proto.localised_name = proto.name .. " (" .. (proto.subgroup or "nil") .. ")"
  end
end

--------------------------------------------------------------------------------
-- 3) Equipment names
--------------------------------------------------------------------------------
local equipment_types = {
  "battery-equipment", "belt-immunity-equipment", "active-defense-equipment",
  "energy-shield-equipment", "generator-equipment", "movement-bonus-equipment",
  "night-vision-equipment", "roboport-equipment", "solar-panel-equipment"
}

for _, t in ipairs(equipment_types) do
  if data.raw[t] then
    for name, proto in pairs(data.raw[t]) do
      proto.localised_name = proto.name
    end
  end
end

--------------------------------------------------------------------------------
-- 4) Entity names
--------------------------------------------------------------------------------
local entity_types = {
  "accumulator", "ammo-turret", "arithmetic-combinator", "artillery-turret",
  "artillery-wagon", "assembling-machine", "beacon", "boiler", "car",
  "cargo-wagon", "character-corpse", "combat-robot", "constant-combinator",
  "construction-robot", "container", "corpse", "curved-rail",
  "decider-combinator", "electric-energy-interface", "electric-pole",
  "electric-turret", "fluid-turret", "fluid-wagon", "furnace", "gate",
  "generator", "heat-interface", "heat-pipe", "infinity-container",
  "infinity-pipe", "inserter", "item-request-proxy", "lab", "lamp",
  "land-mine", "loader", "locomotive", "logistic-container", "logistic-robot",
  "mining-drill", "offshore-pump", "pipe", "pipe-to-ground", "player-port",
  "power-switch", "programmable-speaker", "pump", "radar", "rail-chain-signal",
  "rail-signal", "reactor", "resource", "roboport", "rocket-silo",
  "rocket-silo-rocket", "simple-entity", "simple-entity-with-force",
  "simple-entity-with-owner", "solar-panel", "splitter", "storage-tank",
  "straight-rail", "train-stop", "transport-belt", "tree", "turret",
  "underground-belt", "unit", "unit-spawner", "wall"
}

for _, t in ipairs(entity_types) do
  if data.raw[t] then
    for name, proto in pairs(data.raw[t]) do
      proto.localised_name = proto.name
    end
  end
end

--------------------------------------------------------------------------------
-- 5) Virtual signals, fluids, technologies
--------------------------------------------------------------------------------
for name, proto in pairs(data.raw["virtual-signal"] or {}) do
  proto.localised_name = proto.name
end

for name, proto in pairs(data.raw.fluid or {}) do
  proto.localised_name = proto.name
end

for name, proto in pairs(data.raw.technology or {}) do
  proto.localised_name = proto.name
end
