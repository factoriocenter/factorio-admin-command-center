-- scripts/startup-settings/remove_fuel_usage.lua
-- Converts supported fuel-based entities (burner/fluid energy sources)
-- to void energy so they can run without any fuel input.

local supported_types = {
  "agricultural-tower",
  "assembling-machine",
  "boiler",
  "burner-generator",
  "car",
  "furnace",
  "inserter",
  "lab",
  "locomotive",
  "mining-drill",
  "reactor",
  "rocket-silo",
  "spider-vehicle",
}

for _, prototype_type in ipairs(supported_types) do
  local prototypes = data.raw[prototype_type]
  if prototypes then
    for _, prototype in pairs(prototypes) do
      local energy_source = prototype.energy_source
      if type(energy_source) == "table" and (energy_source.type == "burner" or energy_source.type == "fluid") then
        prototype.energy_source = { type = "void" }
      end
    end
  end
end
