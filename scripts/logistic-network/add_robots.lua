-- scripts/logistic-network/add_robots.lua
-- Insere 50 construction-robots e 50 logistic-robots no inventário do jogador.
-- Se o mod “quality” estiver ativo, insere como legendary; caso contrário, insere qualidade normal.

local M = {}

--- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local quality_enabled = script.active_mods["quality"] ~= nil
  if quality_enabled then
    player.insert{ name = "construction-robot", count = 50, quality = "legendary" }
    player.insert{ name = "logistic-robot",    count = 50, quality = "legendary" }
  else
    player.insert{ name = "construction-robot", count = 50 }
    player.insert{ name = "logistic-robot",    count = 50 }
  end

  player.print({ "facc.add-robots-msg" })
end

return M
