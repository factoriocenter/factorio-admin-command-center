-- scripts/startup-settings/ignore_recipe_inputs.lua
-- Removes ingredient requirements from all recipes.

local recipes = data.raw.recipe or {}

for _, recipe in pairs(recipes) do
  recipe.ingredients = {}

  if type(recipe.normal) == "table" then
    recipe.normal.ingredients = {}
  end

  if type(recipe.expensive) == "table" then
    recipe.expensive.ingredients = {}
  end
end
