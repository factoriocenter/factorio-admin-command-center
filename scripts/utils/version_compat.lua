-- Shared by the data and control stages. Select APIs using the engine version,
-- not the FACC package version (the 2.0 fallback uses the same Lua sources).
local active_mods = script and script.active_mods or mods
local major, minor = active_mods.base:match("^(%d+)%.(%d+)")

local M = {}
M.is_2_1 = tonumber(major) > 2 or (tonumber(major) == 2 and tonumber(minor) >= 1)

function M.set_recipe_category(recipe, category)
  recipe.category = nil
  recipe.categories = nil
  if M.is_2_1 then
    recipe.categories = { category or "crafting" }
  else
    recipe.category = category or "crafting"
  end
end

return M
