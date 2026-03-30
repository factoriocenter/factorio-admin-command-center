-- scripts/power/solar_power_multiplier.lua
-- Sets surface solar power multiplier.

local M = {}
local math_util = require("scripts/utils/flib_math")

function M.run(player, value)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local multiplier = math_util.clamp_number(value, 0, 20, 1)
  player.surface.solar_power_multiplier = multiplier
  player.print({"facc.surface-solar-power-multiplier-set", multiplier})
end

return M
