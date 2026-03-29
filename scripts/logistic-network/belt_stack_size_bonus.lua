-- scripts/logistic-network/belt_stack_size_bonus.lua
-- Live slider: adjusts belt stack size bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "belt_stack_size_bonus", {
    max_bonus = 100,
    min_value = 0,
    integer = true
  })
end

return M
