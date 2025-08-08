-- scripts/character/long_reach.lua
-- Slider-driven reach bonuses that stack with anything the game/mods grant.
-- Live slider: adjusts character reach/build/drop bonuses (0..100).
-- Removes previous slider bonus before applying the new one.
-- 
-- SAFETY
-- • Never set a negative bonus; we clamp with math.max(0, ...).
-- • This avoids the "New value must be >= 0" crash.

local M = {}

local MAX_BONUS = 100

--- Clamp helper
local function clamp01k(x)
  x = tonumber(x) or 0
  if x < 0 then return 0 end
  if x > MAX_BONUS then return MAX_BONUS end
  return x
end

--- Apply new slider value.
-- Removes the previous slider effect and applies the new one,
-- preserving all external bonuses.
-- @param player     LuaPlayer
-- @param old_slider number  previous slider value (0..100)
-- @param new_slider number  new slider value (0..100)
function M.apply(player, old_slider, new_slider)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local force     = player.force
  local old_bonus = clamp01k(old_slider)
  local new_bonus = clamp01k(new_slider)

  -- Build distance
  do
    local cur   = force.character_build_distance_bonus or 0
    local base  = cur - old_bonus
    force.character_build_distance_bonus = math.max(0, base + new_bonus)
  end

  -- Reach distance
  do
    local cur   = force.character_reach_distance_bonus or 0
    local base  = cur - old_bonus
    force.character_reach_distance_bonus = math.max(0, base + new_bonus)
  end

  -- Resource reach distance
  do
    local cur   = force.character_resource_reach_distance_bonus or 0
    local base  = cur - old_bonus
    force.character_resource_reach_distance_bonus = math.max(0, base + new_bonus)
  end

  -- Item drop distance
  do
    local cur   = force.character_item_drop_distance_bonus or 0
    local base  = cur - old_bonus
    force.character_item_drop_distance_bonus = math.max(0, base + new_bonus)
  end
end

return M
