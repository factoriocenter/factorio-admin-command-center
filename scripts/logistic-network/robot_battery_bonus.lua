-- scripts/logistic-network/robot_battery_bonus.lua
-- Live slider: adjusts worker robots battery bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "worker_robots_battery_modifier", {
    max_bonus = 1000,
    min_value = 0,
    integer = false
  })
end

return M
