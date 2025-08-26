-- scripts/startup-settings/infinite_resources.lua
-- When the setting 'facc-infinite-resources' is active,
-- marks all resources as infinite and fixes autoplace richness based on multipliers.
--
-- Separate multipliers for solid vs fluid resources (resource.category), with
-- robust detection for modded categories: we treat as "fluid" if the category
-- string contains "fluid" OR if the prototype's minable products include fluids.
-- We also fallback to the legacy single multiplier if present in older saves.

if not (settings.startup["facc-infinite-resources"] and settings.startup["facc-infinite-resources"].value) then
  return
end

--- Parse a "Nx" string (e.g., "5x") into a number (5). Returns 1 on failure.
local function parse_x(str)
  if type(str) ~= "string" then return 1 end
  local n = tonumber(str:match("^(%d+)x$"))
  return n or 1
end

-- Read new settings; if absent in old saves, fall back to legacy single-setting.
local legacy = (settings.startup["facc-infinite-resources-multiplier"]
                and settings.startup["facc-infinite-resources-multiplier"].value) or nil

local solid_str = (settings.startup["facc-infinite-resources-multiplier-solid"]
                  and settings.startup["facc-infinite-resources-multiplier-solid"].value)
                  or legacy or "1x"

local fluid_str = (settings.startup["facc-infinite-resources-multiplier-fluid"]
                  and settings.startup["facc-infinite-resources-multiplier-fluid"].value)
                  or legacy or "1x"

local MULT_SOLID = parse_x(solid_str)
local MULT_FLUID = parse_x(fluid_str)

-- Resources that we do not want to affect
local blacklist = {
  ["bitumen-seep"] = true,
}

--- Returns true if the resource prototype produces a fluid via minable results.
-- Works for both {result=...} and {results={...}} shapes and array-like forms.
local function prototype_outputs_fluid(res)
  local fluids = data.raw.fluid or {}
  local m = res.minable or res.mineable -- some mods might misuse the key
  if not m then return false end

  -- Single result form
  if m.result and fluids[m.result] then
    return true
  end

  -- Multi-results form
  local results = m.results
  if results then
    for _, r in pairs(results) do
      if r.type == "fluid" then
        return true
      end
      local name = r.name or r[1]
      if name and fluids[name] then
        return true
      end
    end
  end

  return false
end

--- Heuristic: treat as "fluid" if category == "basic-fluid",
-- or category contains the substring "fluid", OR its minable products are fluids.
local function is_fluid_resource_prototype(res)
  local cat = res.category or "basic-solid"
  if type(cat) == "string" and cat:find("fluid", 1, true) then
    return true
  end
  return prototype_outputs_fluid(res)
end

--- Make a resource infinite and apply category-specific autoplace richness.
-- @param resource table (prototype from data.raw.resource)
local function make_resource_infinite(resource)
  -- 1) Infinite and zero depletion
  resource.infinite = true
  resource.infinite_resource = true
  resource.infinite_depletion_amount = 0

  -- 2) Ensure minimum/normal percentages
  resource.minimum = 100
  resource.normal  = 100

  -- 3) Remove counting stages
  if resource.stage_counts then
    for i = 1, #resource.stage_counts do
      resource.stage_counts[i] = 0
    end
  end

  -- 4) Category-based richness (fluid vs solid)
  local mult = is_fluid_resource_prototype(resource) and MULT_FLUID or MULT_SOLID

  if resource.autoplace then
    -- Use 'mult' as a fixed richness base; multiplier left at 0 for stability.
    resource.autoplace.richness_base       = mult
    resource.autoplace.richness_multiplier = 0
  end
end

-- Apply to all data.raw.resource prototypes
for name, res in pairs(data.raw.resource) do
  if not blacklist[name] then
    make_resource_infinite(res)
  end
end
