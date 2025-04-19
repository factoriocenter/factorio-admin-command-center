-- data-final-fixes.lua
-- Custom GUI styles for Factorio Admin Command Center (FACC)
-- Only defines the close button style, since confirm now uses a native one

-- Reference to default styles
local default = data.raw["gui-style"].default
local slot_button = default["slot_button"]

-- Multiline textbox style for Lua console input
default["facc_console_input_style"] = {
  type = "textbox_style",
  parent = "textbox",
  minimal_width = 650,
  minimal_height = 200,
  maximal_width = 700,
  maximal_height = 400,
  top_padding = 4,
  bottom_padding = 4,
  left_padding = 6,
  right_padding = 6,
  word_wrap = true
}