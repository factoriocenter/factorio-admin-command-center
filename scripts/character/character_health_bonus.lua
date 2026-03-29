-- scripts/character/character_health_bonus.lua
-- Live slider: adjusts force character health bonus.

local M = {}
local force_bonus_slider = require("scripts/utils/force_bonus_slider")

function M.apply(player, old, new)
  return force_bonus_slider.apply(player, old, new, "character_health_bonus", {
    max_bonus = 1000,
    min_value = 0,
    integer = true
  })
end

return M
