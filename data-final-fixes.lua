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
