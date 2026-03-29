-- scripts/logistic-network/bulk_inserter_capacity_bonus.lua
-- Live slider: adjusts bulk inserter capacity bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

local MAX_CAPACITY = 254

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "bulk_inserter_capacity_bonus", {
    max_bonus = MAX_CAPACITY,
    min_value = 0,
    max_value = MAX_CAPACITY,
    integer = true
  })
end

return M
