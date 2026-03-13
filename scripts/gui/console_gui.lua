-- scripts/gui/console_gui.lua
-- Lua Console GUI for entering arbitrary Lua commands during play.
-- Stores the last-entered command in `storage.facc_last_command`,
-- which survives save/load and even returning to the main menu.

local M = {}
local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")
local gui_events = require("scripts/events/gui_events")

--------------------------------------------------------------------------------
-- Toggles the visibility of the Lua Console window.
-- If opening: builds the GUI, pre-fills the textbox from storage.
-- If closing: saves the textbox contents back into storage and destroys it.
-- @param player LuaPlayer  — the player who clicked “Console”
--------------------------------------------------------------------------------
function M.toggle_console_gui(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Initialize our storage slot if needed
  local last_cmd = flib_table.get_or_insert(storage, "facc_last_command", "")
  if type(last_cmd) ~= "string" then
    storage.facc_last_command = tostring(last_cmd or "")
  end

  local screen = player.gui.screen

  -- If it’s already open, save & close
  if screen.facc_console_frame then
    storage.facc_last_command = screen.facc_console_frame.facc_textbox.text or ""
    screen.facc_console_frame.destroy()
    return
  end

  -- Otherwise, build the console window through FLib GUI definitions
  local _, frame = flib_gui.add(screen, {
    type = "frame",
    name = "facc_console_frame",
    caption = {"facc.console-title"},
    direction = "vertical",
    style_mods = {
      minimal_width = 600,
      maximal_width = 800
    },
    children = {
      {
        type = "label",
        caption = {"facc.console-instruction"}
      },
      {
        type = "text-box",
        name = "facc_textbox",
        text = storage.facc_last_command,
        style = "facc_console_input_style",
        handler = { [defines.events.on_gui_text_changed] = gui_events.handlers.console_text_changed },
        elem_mods = {
          word_wrap = true
        },
        style_mods = {
          minimal_height = 200,
          horizontally_stretchable = true
        }
      },
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_align = "right",
          horizontal_spacing = 8
        },
        children = {
          {
            type = "button",
            name = "facc_console_close",
            caption = {"facc.console-close"},
            style = "back_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          },
          {
            type = "button",
            name = "facc_console_exec",
            caption = {"facc.console-exec"},
            style = "confirm_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          }
        }
      }
    }
  })
  frame.auto_center        = true
end

--------------------------------------------------------------------------------
-- Reads the text from the console textbox, stores it, and executes it safely.
-- Wraps the user code in a `pcall` so runtime errors print back to the player.
-- @param player LuaPlayer  — the player who clicked “Execute”
--------------------------------------------------------------------------------
function M.exec_console_command(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local frame = player.gui.screen.facc_console_frame
  if not (frame and frame.facc_textbox) then
    player.print({"facc.console-msg-failure"})
    return
  end

  -- Grab & persist the command
  local cmd = frame.facc_textbox.text or ""
  storage.facc_last_command = cmd

  -- Replace deprecated `game.player` with indexed API
  cmd = cmd:gsub("game%.player([^s])", "game.players[" .. player.index .. "]%1")

  -- Try to compile user code wrapped in pcall
  local func, syntax_err = loadstring(
    "local status, err = pcall(function() " .. cmd .. " end) " ..
    "if not status then game.players[" .. player.index .. "].print(err) end"
  )

  -- If compilation failed, try printing the expression result directly
  if not func then
    func, syntax_err = loadstring("game.players[" .. player.index .. "].print(" .. cmd .. ")")
  end

  -- Execute and report errors
  if func then
    local success, runtime_err = pcall(func)
    if not success then
      -- Print only the first line of the error message
      player.print(runtime_err:match("^[^\n]*"))
    else
      player.print({"facc.console-msg-success"})
    end
  else
    player.print(syntax_err:match("^[^\n]*"))
  end
end

--------------------------------------------------------------------------------
gui_events.set_console_gui_api(M)

return M
