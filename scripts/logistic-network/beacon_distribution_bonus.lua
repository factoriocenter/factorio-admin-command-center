-- scripts/logistic-network/beacon_distribution_bonus.lua
-- Live slider: adjusts beacon distribution bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "beacon_distribution_modifier", {
    max_bonus = 1000,
    min_value = 0,
    integer = false
  })
end

return M
