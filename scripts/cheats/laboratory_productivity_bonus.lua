-- scripts/cheats/laboratory_productivity_bonus.lua
-- Live slider: adjusts laboratory productivity bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "laboratory_productivity_bonus", {
    max_bonus = 1000,
    min_value = 0,
    integer = false
  })
end

return M
