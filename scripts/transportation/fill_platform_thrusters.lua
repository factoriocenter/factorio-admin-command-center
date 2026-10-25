-- scripts/transportation/fill_platform_thrusters.lua
-- Fills the current platform thrusters with the fluids required by each fluidbox.
-- Uses the versioned fluid API instead of hardcoded fluid names.

local M = {}
local compat = require("scripts/utils/mod_compat")
local fluid_compat = require("scripts/utils/fluid_compat")

local space_age_enabled = compat.is_space_age_stack_active()

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
        local fluid_name = fluid_compat.get_required_fluid_name(thruster, i)
        if fluid_name and fluid_compat.fill_storage(thruster, i, fluid_name) then
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
