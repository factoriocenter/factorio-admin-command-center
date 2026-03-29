-- scripts/logistic-network/inserter_stack_size_bonus.lua
-- Live slider: adjusts inserter stack size bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "inserter_stack_size_bonus", {
    max_bonus = 100,
    min_value = 0,
    integer = true
  })
end

return M
