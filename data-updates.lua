-- data-updates.lua
require("prototypes.achievements_overrides")

local util = require("util")

local base = data.raw.character and data.raw.character["character"]
if base then
  local ghost = util.table.deepcopy(base)

  ghost.name = "facc-ghost-character"
  ghost.localised_name = {"entity-name.facc-ghost-character"}
  ghost.collision_mask = ghost.collision_mask or {}
  ghost.collision_mask.layers = {}
  ghost.collision_box = ghost.collision_box

  data:extend({ ghost })
end
