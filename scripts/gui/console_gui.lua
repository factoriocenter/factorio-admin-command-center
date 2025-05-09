-- scripts/gui/console_gui.lua
-- Lua Console GUI for entering arbitrary Lua commands
-- Provides functions to open/close the console window and execute the entered code

local M = {}

--------------------------------------------------------------------------------
-- Opens or closes the Lua Console GUI
-- @param player LuaPlayer
--------------------------------------------------------------------------------
function M.toggle_console_gui(player)
  -- Check permission
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  global = global or {}  -- Ensure global table exists for storing last command
  local gui = player.gui.screen

  -- If console frame is already open, save last command and close it
  if gui.facc_console_frame then
    global.facc_last_command = gui.facc_console_frame.facc_textbox.text or ""
    gui.facc_console_frame.destroy()
    return
  end

  -- Otherwise, create and open the console frame
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

  -- Close button
  button_flow.add{
    type = "button",
    name = "facc_console_close",
    caption = {"facc.console-close"},
    style = "back_button"
  }

  -- Execute button
  button_flow.add{
    type = "button",
    name = "facc_console_exec",
    caption = {"facc.console-exec"},
    style = "confirm_button"
  }
end

--------------------------------------------------------------------------------
-- Executes the Lua command from the text box
-- @param player LuaPlayer
--------------------------------------------------------------------------------
function M.exec_console_command(player)
  -- Check permission
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Locate the textbox inside the console frame
  local frame = player.gui.screen.facc_console_frame
  if not (frame and frame.facc_textbox) then
    player.print({"facc.console-msg-failure"})
    return
  end

  local cmd = frame.facc_textbox.text or ""
  global.facc_last_command = cmd

  -- Replace deprecated game.player usage with index-based API
  cmd = cmd:gsub("game%.player([^s])", "game.players[" .. player.index .. "]%1")

  -- Attempt to compile user code safely, wrapping in pcall
  local func, syntax_err = loadstring(
    "local status, err = pcall(function() " .. cmd .. " end) " ..
    "if not status then game.players[" .. player.index .. "].print(err) end"
  )

  -- If initial compile failed, try to print the expression directly
  if not func then
    func, syntax_err = loadstring("game.players[" .. player.index .. "].print(" .. cmd .. ")")
  end

  -- Execute the compiled function
  if func then
    local success, runtime_err = pcall(func)
    if not success then
      -- Print only the first line of error
      player.print(runtime_err:match("^[^\n]*"))
    else
      player.print({"facc.console-msg-success"})
    end
  else
    -- Compilation failed: show syntax error
    player.print(syntax_err:match("^[^\n]*"))
  end
end

return M
