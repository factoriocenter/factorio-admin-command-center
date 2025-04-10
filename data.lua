-- data.lua
-- Define a custom textbox style for the Lua Console and register a custom input (Ctrl + ])

data.raw["gui-style"].default["some_luaconsole_input_textbox"] = {
  type = "textbox_style",
  name = "some_luaconsole_input_textbox",
  parent = "textbox",
  minimal_width = 650,
  minimal_height = 200,
}

data:extend({
  {
    type = "custom-input",
    name = "facc_toggle_gui",
    key_sequence = "CONTROL + PERIOD",
    localised_name = {"controls.facc_toggle_gui"},
    localised_description = {"controls.facc_toggle_gui_description"}
  }
})

