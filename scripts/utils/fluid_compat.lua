-- Factorio 2.1 moved LuaFluidBox accessors onto LuaEntity and changed the
-- set_fluid return value from Fluid? to FluidAmount. Keep those differences here.
local version = require("scripts/utils/version_compat")
local M = {}

local function fluid_name(fluid)
  if type(fluid) == "string" then return fluid ~= "" and fluid or nil end
  return fluid and fluid.name or nil
end

function M.get_required_fluid_name(entity, index)
  local prototype
  local filter
  if version.is_2_1 then
    prototype = entity.get_fluid_box_prototype(index)
    filter = entity.get_fluid_filter(index)
  else
    prototype = entity.fluidbox.get_prototype(index)
    filter = entity.fluidbox.get_filter(index)
  end

  if prototype then
    -- A merged crafting fluidbox can expose multiple prototypes in 2.1.
    if prototype.object_name then
      local name = fluid_name(prototype.filter)
      if name then return name end
    else
      for _, entry in pairs(prototype) do
        local name = fluid_name(entry.filter)
        if name then return name end
      end
    end
  end
  local name = fluid_name(filter)
  if name then return name end
  if not version.is_2_1 then
    name = fluid_name(entity.fluidbox.get_locked_fluid(index))
    if name then return name end
  end
  return fluid_name(entity.get_fluid(index))
end

function M.fill_storage(entity, index, name)
  local capacity
  if version.is_2_1 then
    capacity = entity.get_fluid_capacity(index)
  else
    capacity = entity.fluidbox.get_capacity(index)
  end
  if not capacity or capacity <= 0 then return false end
  local result = entity.set_fluid(index, { name = name, amount = capacity })
  if version.is_2_1 then
    return type(result) == "number" and result > 0
  end
  return result ~= nil and result.amount > 0
end

return M
