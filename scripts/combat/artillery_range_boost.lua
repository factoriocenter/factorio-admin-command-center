-- scripts/combat/artillery_range_boost.lua
-- Live slider: adjusts artillery range modifier bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "artillery_range_modifier", {
    max_bonus = 1000,
    min_value = 0,
    integer = false
  })
end

return M
