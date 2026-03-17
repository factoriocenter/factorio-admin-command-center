-- scripts/logistic-network/add_robots.lua
-- Insere 50 construction-robots e 50 logistic-robots no inventário do jogador.
-- Se o mod “quality” estiver ativo, insere como legendary; caso contrário, insere qualidade normal.

local M = {}
local compat = require("scripts/utils/mod_compat")

--- @param player LuaPlayer
function M.run(player)
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local quality_enabled = compat.is_mod_active("quality")
  local inserted_construction = 0
  local inserted_logistic = 0

  if quality_enabled then
    inserted_construction = compat.safe_player_insert(player, { name = "construction-robot", count = 50, quality = "legendary" })
    inserted_logistic = compat.safe_player_insert(player, { name = "logistic-robot", count = 50, quality = "legendary" })
  else
    inserted_construction = compat.safe_player_insert(player, { name = "construction-robot", count = 50 })
    inserted_logistic = compat.safe_player_insert(player, { name = "logistic-robot", count = 50 })
  end

  if inserted_construction > 0 or inserted_logistic > 0 then
    player.print({ "facc.add-robots-msg" })
  else
    player.print({ "facc.add-robots-missing" })
  end
end

return M
