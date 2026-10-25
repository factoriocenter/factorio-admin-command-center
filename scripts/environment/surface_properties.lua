-- scripts/environment/surface_properties.lua
-- Surface properties editor actions (runtime stage).

local M = {}
local math_util = require("scripts/utils/flib_math")
local compat = require("scripts/utils/mod_compat")

local SPACE_AGE_REQUIRED_KEYS = {
  pressure = true,
  ["magnetic-field"] = true,
  gravity = true
}

local function is_allowed_player(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return false
  end
  return true
end

local function get_surface(player)
  if not (player and player.valid and player.surface and player.surface.valid) then
    return nil
  end
  return player.surface
end

local function format_number(value)
  if value == math.floor(value) then
    return tostring(math.floor(value))
  end
  return string.format("%.2f", value)
end

function M.set_freeze_daytime(player, enabled)
  if not is_allowed_player(player) then
    return
  end

  local surface = get_surface(player)
  if not surface then
    return
  end

  surface.freeze_daytime = enabled
  if enabled then
    player.print({"facc.surface-freeze-daytime-enabled"})
  else
    player.print({"facc.surface-freeze-daytime-disabled"})
  end
end

function M.set_peaceful_mode(player, enabled)
  if not is_allowed_player(player) then
    return
  end

  local surface = get_surface(player)
  if not surface then
    return
  end

  surface.peaceful_mode = enabled
  if enabled then
    player.print({"facc.surface-peaceful-mode-enabled"})
  else
    player.print({"facc.surface-peaceful-mode-disabled"})
  end
end

function M.set_no_enemies_mode(player, enabled)
  if not is_allowed_player(player) then
    return
  end

  local surface = get_surface(player)
  if not surface then
    return
  end

  local ok = pcall(function()
    surface.no_enemies_mode = enabled
  end)

  if not ok then
    player.print({"facc.surface-property-unsupported", "no_enemies_mode"})
    return
  end

  if enabled then
    player.print({"facc.surface-no-enemies-enabled"})
  else
    player.print({"facc.surface-no-enemies-disabled"})
  end
end

function M.set_daytime(player, value)
  if not is_allowed_player(player) then
    return
  end

  local surface = get_surface(player)
  if not surface then
    return
  end

  local daytime = math_util.clamp_number(value, 0, 1, 0.5)
  surface.daytime = daytime
  player.print({"facc.surface-daytime-set", format_number(daytime)})
end

function M.set_midday(player)
  M.set_daytime(player, 0.5)
end

function M.set_midnight(player)
  M.set_daytime(player, 0)
end

function M.set_property(player, property_name, raw_value)
  if not is_allowed_player(player) then
    return
  end

  local surface = get_surface(player)
  if not surface then
    return
  end

  if SPACE_AGE_REQUIRED_KEYS[property_name] and not compat.is_space_age_stack_active() then
    player.print({"facc.surface-property-no-space-age"})
    return
  end

  local value = math_util.clamp_number(raw_value, 0, 100000, 0)

  local ok_get = pcall(function() return surface.get_property(property_name) end)
  if not ok_get then
    player.print({"facc.surface-property-unsupported", property_name})
    return
  end

  local ok_set = pcall(function() surface.set_property(property_name, value) end)
  if not ok_set then
    player.print({"facc.surface-property-unsupported", property_name})
    return
  end

  player.print({"facc.surface-property-set", property_name, format_number(value)})
end

return M
