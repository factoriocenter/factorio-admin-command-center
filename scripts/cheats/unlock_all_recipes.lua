-- scripts/unlocks/unlock_all_recipes.lua
-- This module enables all available recipes for the player's force.

local M = {}

function M.run(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  for _, recipe in pairs(player.force.recipes) do
    recipe.enabled = true
  end

  player.print({"facc.unlock-recipes-msg"})
end

return M
