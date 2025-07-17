-- scripts/character/long_reach.lua
-- Toggle “Long Reach” bonuses for the player’s force.
-- Grants or removes extra build/reach/drop distances,
-- always resetting to the default base value when disabled.

local M = {}

--- Toggles long-reach bonuses.
-- @param player LuaPlayer – the invoking player
-- @param enabled boolean – true to add bonuses, false to reset to default
function M.run(player, enabled)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local default = 0   -- Factorio's built-in default distance bonus
  local bonus   = 100  -- Your extra reach amount (can be adjusted)

  local force = player.force

  if enabled then
    -- set to default + bonus (avoids stacking if toggled multiple times)
    force.character_build_distance_bonus          = default + bonus
    force.character_reach_distance_bonus          = default + bonus
    force.character_resource_reach_distance_bonus = default + bonus
    force.character_item_drop_distance_bonus      = default + bonus
    player.print({"facc.long-reach-activated"})
  else
    -- always reset back to default, regardless of current value
    force.character_build_distance_bonus          = default
    force.character_reach_distance_bonus          = default
    force.character_resource_reach_distance_bonus = default
    force.character_item_drop_distance_bonus      = default
    player.print({"facc.long-reach-deactivated"})
  end
end

return M
