-- scripts/logistic-network/following_robot_lifetime_bonus.lua
-- Live slider: adjusts following robots lifetime bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "following_robots_lifetime_modifier", {
    max_bonus = 1000,
    min_value = 0,
    integer = false
  })
end

return M
