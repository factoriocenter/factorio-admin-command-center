-- data-final-fixes.lua
-- Custom GUI styles for Factorio Admin Command Center (FACC).
-- Defines the console textbox style and conditionally loads
-- the internal_names and infinite_resources scripts if enabled.

local default = data.raw["gui-style"].default

default["facc_console_input_style"] = {
  type             = "textbox_style",
  parent           = "textbox",
  minimal_width    = 650,
  minimal_height   = 200,
  maximal_width    = 700,
  maximal_height   = 400,
  top_padding      = 4,
  bottom_padding   = 4,
  left_padding     = 6,
  right_padding    = 6,
  word_wrap        = true
}

-- Load internal_names.lua when that setting is enabled
if settings.startup["facc-internal-names"]
    and settings.startup["facc-internal-names"].value then
  local ok, err = pcall(require, "internal_names")
  if not ok then
    error("FACC: failed to load internal_names.lua: " .. tostring(err))
  end
end

-- Load infinite_resources.lua when that setting is enabled
if settings.startup["facc-infinite-resources"]
    and settings.startup["facc-infinite-resources"].value then
  require("scripts/startup-settings/infinite_resources")
end

-- Optional: make all mining drills effectively instant
if settings.startup["facc-instant-mining-drills"]
    and settings.startup["facc-instant-mining-drills"].value then
  local multiplier = 1000 -- big enough to mine almost instantly
  local drills = data.raw["mining-drill"] or {}
  for _, drill in pairs(drills) do
    local base_speed = drill.mining_speed or 1
    drill.mining_speed = base_speed * multiplier
  end
end

-- Optional: make assembling machines/furnaces craft instantly
if settings.startup["facc-instant-crafting-machines"]
    and settings.startup["facc-instant-crafting-machines"].value then
  local multiplier = 1000000 -- force machine crafts to finish in ~1 tick
  -- Prototype types that expose crafting_speed
  local crafting_types = { "assembling-machine", "furnace", "rocket-silo" }
  for _, type_name in ipairs(crafting_types) do
    local prototypes = data.raw[type_name]
    if prototypes then
      for _, machine in pairs(prototypes) do
        local base_speed = machine.crafting_speed or 1
        machine.crafting_speed = base_speed * multiplier
      end
    end
  end
end

-- Optional: remove electricity requirements from supported electric entities
if settings.startup["facc-remove-electricity-usage"]
    and settings.startup["facc-remove-electricity-usage"].value then
  require("scripts/startup-settings/remove_electricity_usage")
end

-- Optional: remove fuel requirements from supported burner/fluid entities
if settings.startup["facc-remove-fuel-usage"]
    and settings.startup["facc-remove-fuel-usage"].value then
  require("scripts/startup-settings/remove_fuel_usage")
end

-- Optional: remove all recipe ingredient inputs
if settings.startup["facc-ignore-recipe-inputs"]
    and settings.startup["facc-ignore-recipe-inputs"].value then
  require("scripts/startup-settings/ignore_recipe_inputs")
end
