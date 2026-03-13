-- data-updates.lua
require("prototypes.achievements_overrides")
local flib_data_util = require("__flib__.data-util")

local base = data.raw.character and data.raw.character["character"]
if base then
  local ghost = flib_data_util.copy_prototype(base, "facc-ghost-character")

  ghost.localised_name = {"entity-name.facc-ghost-character"}
  ghost.collision_mask = ghost.collision_mask or {}
  ghost.collision_mask.layers = {}
  ghost.collision_box = ghost.collision_box

  data:extend({ ghost })
end
