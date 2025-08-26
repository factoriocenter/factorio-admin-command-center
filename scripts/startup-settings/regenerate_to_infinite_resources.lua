-- scripts/startup-settings/regenerate_to_infinite_resources.lua
-- Regenerate all finite resource patches and top up infinite ones on a surface.
-- Applies distinct multipliers for solid vs fluid resources with robust detection.

local M = {}

--- Parse "Nx" (e.g., "10x") or return 1.
local function parse_x(str)
  if type(str) ~= "string" then return 1 end
  local n = tonumber(str:match("^(%d+)x$"))
  return n or 1
end

--- Read both multipliers with legacy fallback.
-- @return number mult_solid, number mult_fluid
local function read_multipliers()
  local legacy = (settings.startup["facc-infinite-resources-multiplier"]
                  and settings.startup["facc-infinite-resources-multiplier"].value) or nil

  local solid_str = (settings.startup["facc-infinite-resources-multiplier-solid"]
                    and settings.startup["facc-infinite-resources-multiplier-solid"].value)
                    or legacy or "1x"

  local fluid_str = (settings.startup["facc-infinite-resources-multiplier-fluid"]
                    and settings.startup["facc-infinite-resources-multiplier-fluid"].value)
                    or legacy or "1x"

  return parse_x(solid_str), parse_x(fluid_str)
end

--- Detect whether a runtime resource entity is fluid-category.
-- Heuristics:
--   1) resource_category/category string contains "fluid"
--   2) any mineable product has type == "fluid"
-- @param res LuaEntity (type = "resource")
-- @return boolean
local function is_fluid_resource(res)
  local proto = res and res.prototype
  if not proto then return false end

  local cat = proto.resource_category or proto.category or "basic-solid"
  if type(cat) == "string" and string.find(cat, "fluid", 1, true) then
    return true
  end

  local mp = proto.mineable_properties
  if mp and mp.products then
    for _, p in pairs(mp.products) do
      if p and p.type == "fluid" then
        return true
      end
    end
  end

  return false
end

--- Regenerates and tops up all resource patches on the given surface.
-- @param surface LuaSurface — the surface to process
function M.run_on_surface(surface)
  if not (surface and surface.find_entities_filtered) then return end

  local mult_solid, mult_fluid = read_multipliers()

  -- 1) Destroy all finite resources and collect their names
  local to_regen = {}
  for _, resource in ipairs(surface.find_entities_filtered{ type = "resource" }) do
    if not resource.prototype.infinite_resource then
      to_regen[resource.name] = true
      resource.destroy()
    end
  end

  -- 2) Regenerate each collected resource type (pcall skips errors)
  for resource_name in pairs(to_regen) do
    pcall(function()
      surface.regenerate_entity(resource_name)
    end)
  end

  -- 3) Top up all remaining resource patches according to their category
  for _, resource in ipairs(surface.find_entities_filtered{ type = "resource" }) do
    local normal_amount = resource.prototype.normal_resource_amount
    if normal_amount and normal_amount > 0 then
      local m = is_fluid_resource(resource) and mult_fluid or mult_solid
      local amt = normal_amount * m
      resource.amount         = amt
      resource.initial_amount = amt
    end
  end

  -- 4) Refresh connections on all mining drills
  for _, drill in ipairs(surface.find_entities_filtered{ type = "mining-drill" }) do
    drill.update_connections()
  end
end

return M
