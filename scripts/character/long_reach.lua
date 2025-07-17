-- scripts/character/long_reach.lua
-- Live slider: adjusts character reach/build/drop bonuses (0..100).
-- Removes previous slider bonus before applying the new one.

local M = {}
local MAX_BONUS = 100

--- Applies a new reach bonus based on slider movement.
-- @param player LuaPlayer – the invoking player
-- @param old number       – the previous slider value
-- @param new number       – the new slider value
function M.apply(player, old, new)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- Clamp slider value
  local bonus = math.max(0, math.min(new, MAX_BONUS))

  local force = player.force

  -- Compute base (remove old slider bonus)
  local base_build     = force.character_build_distance_bonus - old
  local base_reach     = force.character_reach_distance_bonus - old
  local base_resource  = force.character_resource_reach_distance_bonus - old
  local base_drop      = force.character_item_drop_distance_bonus - old

  -- Apply base + new slider bonus
  force.character_build_distance_bonus          = base_build    + bonus
  force.character_reach_distance_bonus          = base_reach    + bonus
  force.character_resource_reach_distance_bonus = base_resource + bonus
  force.character_item_drop_distance_bonus      = base_drop     + bonus
end

return M
