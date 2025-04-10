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
    key_sequence = "CONTROL + RIGHTBRACKET"
  }
})
