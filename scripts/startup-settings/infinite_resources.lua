-- scripts/startup-settings/infinite_resources.lua
-- When the setting 'facc-infinite-resources' is active,
-- marks all resources as infinite and fixes autoplace richness based on multiplier.

if not (settings.startup["facc-infinite-resources"] and settings.startup["facc-infinite-resources"].value) then
  return
end

-- Determine multiplier from startup setting (e.g., "2x" -> 2)
local mult_str   = settings.startup["facc-infinite-resources-multiplier"].value or "1x"
local multiplier = tonumber(mult_str:match("^(%d+)x$")) or 1

-- Resources that we do not want to affect
local blacklist = {
  ["bitumen-seep"] = true,
}

local function make_resource_infinite(resource)
  -- 1) Make infinite and zero depletion
  resource.infinite = true
  resource.infinite_depletion_amount = 0

  -- 2) Ensure minimum and normal percentages
  resource.minimum = 100
  resource.normal  = 100

  -- 3) Remove counting stages
  if resource.stage_counts then
    for i = 1, #resource.stage_counts do
      resource.stage_counts[i] = 0
    end
  end

  -- 4) Set autoplace richness based on multiplier
  if resource.autoplace then
    resource.autoplace.richness_base       = multiplier    -- e.g., 2 = 200%
    resource.autoplace.richness_multiplier = 0
  end
end

-- Apply to all data.raw.resource prototypes
for name, resource in pairs(data.raw.resource) do
  if not blacklist[name] then
    make_resource_infinite(resource)
  end
end
