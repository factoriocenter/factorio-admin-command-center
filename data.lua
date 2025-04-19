-- data.lua
-- Registers the custom input (CTRL + .) for toggling the admin GUI

data:extend({
  {
    type = "custom-input",
    name = "facc_toggle_gui",
    key_sequence = "CONTROL + PERIOD",
    consuming = "game-only",
    localised_name = {"controls.facc_toggle_gui"},
    localised_description = {"controls.facc_toggle_gui_description"}
  }
})
