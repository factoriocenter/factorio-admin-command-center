-- scripts/transportation/fill_platform_thrusters.lua
-- Fills the current platform thrusters with the fluids required by each fluidbox.
-- Uses runtime API fluid storage filters/prototypes instead of hardcoded fluid names.
-- Factorio 2.1 removed LuaFluidBox; fluid storages are accessed directly on LuaEntity.

local M = {}
local compat = require("scripts/utils/mod_compat")

local space_age_enabled = compat.is_space_age_stack_active()

local function get_fluid_prototype_name(fluid_proto)
  if fluid_proto and fluid_proto.valid and type(fluid_proto.name) == "string" and fluid_proto.name ~= "" then
    return fluid_proto.name
  end
  return nil
end

local function get_required_fluid_name(entity, index)
  local ok_proto, proto = pcall(function() return entity.get_fluid_box_prototype(index) end)
  if ok_proto and proto then
    -- Merged crafting machine fluidboxes return an array of prototypes.
    local protos = proto.object_name and { proto } or proto
    for _, p in pairs(protos) do
      local name = p.valid and get_fluid_prototype_name(p.filter)
      if name then
        return name
      end
    end
  end

  local ok_filter, filter = pcall(function() return entity.get_fluid_filter(index) end)
  if ok_filter then
    local name = get_fluid_prototype_name(filter)
    if name then
      return name
    end
  end

  local ok_fluid, fluid = pcall(function() return entity.get_fluid(index) end)
  if ok_fluid and fluid and type(fluid.name) == "string" and fluid.name ~= "" then
    return fluid.name
  end

  return nil
end

local function fill_fluid_storage(entity, index, fluid_name)
  local ok_cap, capacity = pcall(function() return entity.get_fluid_capacity(index) end)
  if not ok_cap or type(capacity) ~= "number" or capacity <= 0 then
    return false
  end

  local ok_set, amount_set = pcall(function()
    return entity.set_fluid(index, { name = fluid_name, amount = capacity })
  end)
  return ok_set and type(amount_set) == "number" and amount_set > 0
end

function M.run(player)
  if not (player and player.valid) then return end
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  if not space_age_enabled then
    player.print({ "facc.fill-thrusters-no-space-age" })
    return
  end

  local surface = player.surface
  if not (surface and surface.valid and surface.platform) then
    player.print({ "facc.fill-thrusters-no-platform" })
    return
  end

  local thrusters = surface.find_entities_filtered{
    force = player.force,
    type = "thruster"
  }

  if #thrusters == 0 then
    player.print({ "facc.fill-thrusters-none" })
    return
  end

  local fueled_count = 0

  for _, thruster in pairs(thrusters) do
    if thruster.valid then
      local filled_any = false

      for i = 1, (thruster.fluids_count or 0) do
        local fluid_name = get_required_fluid_name(thruster, i)
        if fluid_name and fill_fluid_storage(thruster, i, fluid_name) then
          filled_any = true
        end
      end

      if filled_any then
        fueled_count = fueled_count + 1
      end
    end
  end

  if fueled_count > 0 then
    player.print({ "facc.fill-thrusters-msg", fueled_count })
  else
    player.print({ "facc.fill-thrusters-failed" })
  end
end

return M
