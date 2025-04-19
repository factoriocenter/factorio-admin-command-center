-- scripts/utility/console.lua
-- This module provides a function to execute arbitrary Lua code from the global command string.
-- It is used by the GUI console interface to run admin-level commands.

local M = {}

function M.exec(player, code)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Sanitize command (replace deprecated game.player)
  code = code:gsub("game%.player([^s])", "game.players[" .. player.index .. "]%1")

  -- Attempt to load and run the code safely
  local f, compile_err = loadstring(
    "local suc, res = pcall(function() " .. code .. " end)\n" ..
    "if not suc then game.players[" .. player.index .. "].print(res) end"
  )

  if not f then
    f, compile_err = loadstring("game.players[" .. player.index .. "].print(" .. code .. ")")
  end

  if f then
    local ok, runtime_err = pcall(f)
    if not ok then
      player.print(runtime_err:match("^[^\n]*"))
    end
  else
    player.print(compile_err:match("^[^\n]*"))
  end
end

return M
