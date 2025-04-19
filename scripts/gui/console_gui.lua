-- scripts/gui/console_gui.lua
-- Lua Console GUI for entering arbitrary Lua commands

local M = {}

-- Opens or closes the Lua Console GUI
function M.toggle_console_gui(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  global = global or {}  -- Ensure global table exists
  local gui = player.gui.screen

  -- Close console if already open
  if gui.facc_console_frame then
    global.facc_last_command = gui.facc_console_frame.facc_textbox.text or ""
    gui.facc_console_frame.destroy()
    return
  end

  -- Open the console frame
  local frame = gui.add{
    type = "frame",
    name = "facc_console_frame",
    caption = {"facc.console-title"},
    direction = "vertical"
  }
  frame.auto_center = true
  frame.style.minimal_width = 600
  frame.style.maximal_width = 800

  -- Instruction label
  frame.add{
    type = "label",
    caption = {"facc.console-instruction"}
  }

  -- Multiline text box for Lua input
  local textbox = frame.add{
    type = "text-box",
    name = "facc_textbox",
    text = global.facc_last_command or "",
    style = "facc_console_input_style"
  }
  textbox.word_wrap = true
  textbox.style.minimal_height = 200
  textbox.style.horizontally_stretchable = true

  -- Button row (close + execute)
  local button_flow = frame.add{type = "flow", direction = "horizontal"}
  button_flow.style.horizontal_align = "right"
  button_flow.style.horizontal_spacing = 8

  button_flow.add{
    type = "button",
    name = "facc_console_close",
    caption = {"facc.console-close"},
    style = "back_button"
  }

  button_flow.add{
    type = "button",
    name = "facc_console_exec",
    caption = {"facc.console-exec"},
    style = "confirm_button"
  }
end

-- Executes the Lua command from the text box
function M.exec_console_command(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local input = player.gui.screen.facc_console_frame and player.gui.screen.facc_console_frame.facc_textbox
  if not input then
    player.print({"facc.console-msg-failure"})
    return
  end

  local cmd = input.text or ""
  global.facc_last_command = cmd

  -- Replace legacy game.player with proper index-based player
  cmd = cmd:gsub("game%.player([^s])", "game.players[" .. player.index .. "]%1")

  -- Compile and execute command safely
  local func, syntax_err = loadstring("local status, err = pcall(function() " .. cmd .. " end) if not status then game.players[" .. player.index .. "].print(err) end")

  if not func then
    func, syntax_err = loadstring("game.players[" .. player.index .. "].print(" .. cmd .. ")")
  end

  if func then
    local success, runtime_err = pcall(func)
    if not success then
      player.print(runtime_err:match("^[^\n]*"))
    else
      player.print({"facc.console-msg-success"})
    end
  else
    player.print(syntax_err:match("^[^\n]*"))
  end
end

return M
