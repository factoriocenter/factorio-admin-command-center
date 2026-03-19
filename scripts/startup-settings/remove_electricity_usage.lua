-- scripts/startup-settings/remove_electricity_usage.lua
-- Converts supported electric entities to void energy so they can run
-- without requiring an electric network.

local supported_types = {
  "agricultural-tower",
  "arithmetic-combinator",
  "assembling-machine",
  "asteroid-collector",
  "beacon",
  "boiler",
  "constant-combinator",
  "decider-combinator",
  "electric-turret",
  "furnace",
  "inserter",
  "lab",
  "lamp",
  "loader",
  "loader-1x1",
  "mining-drill",
  "offshore-pump",
  "programmable-speaker",
  "pump",
  "radar",
  "reactor",
  "roboport",
  "rocket-silo",
  "selector-combinator",
}

for _, prototype_type in ipairs(supported_types) do
  local prototypes = data.raw[prototype_type]
  if prototypes then
    for _, prototype in pairs(prototypes) do
      local energy_source = prototype.energy_source
      if type(energy_source) == "table" and energy_source.type == "electric" then
        prototype.energy_source = { type = "void" }
      end
    end
  end
end
