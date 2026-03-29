-- scripts/logistic-network/maximum_following_robot_count.lua
-- Live slider: adjusts maximum following robot count bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "maximum_following_robot_count", {
    max_bonus = 1000,
    min_value = 0,
    integer = true
  })
end

return M
