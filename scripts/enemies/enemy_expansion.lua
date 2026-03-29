-- scripts/enemies/enemy_expansion.lua
-- Toggle enemy expansion (biter nest growth)
-- Switch ON: disable expansion; Switch OFF: enable expansion (default)

local M = {}

--- Toggles biter expansion globally.
-- @param player LuaPlayer
-- @param disable_expansion boolean; true to disable expansion, false to enable expansion
function M.run(player, disable_expansion)
    if not is_allowed(player) then
        player.print({ "facc.not-allowed" })
        return
    end

    local ok = pcall(function()
      game.map_settings.enemy_expansion.enabled = not disable_expansion
    end)
    if not ok then
      player.print({ "facc.runtime-compat-error", "facc_enemy_expansion" })
      return
    end

    local enabled_now = game.map_settings.enemy_expansion.enabled == true
    if enabled_now then
      -- switch OFF behavior: expansion enabled
      player.print({ "facc.enemy-expansion-activated" })
    else
      -- switch ON behavior: expansion disabled
      player.print({ "facc.enemy-expansion-deactivated" })
    end
end

return M
