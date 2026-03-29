-- scripts/combat/ammo_damage_boost.lua
-- Live slider: adjusts ammo damage modifiers by delta (new - old).
-- Uses the same LuaForce API style as base game's wave-defense script.

local M = {}
local math_util = require("scripts/utils/flib_math")

local MAX_BONUS = 1000
local MIN_MODIFIER = -1

-- Known ammo categories from Base + Space Age.
-- Unsupported categories are safely ignored via pcall.
local AMMO_CATEGORIES = {
  "bullet",
  "shotgun-shell",
  "cannon-shell",
  "rocket",
  "grenade",
  "landmine",
  "flamethrower",
  "laser",
  "artillery-shell",
  "railgun",
  "tesla",
  "electric",
  "beam",
  "capsule"
}

local function clamp_slider(value)
  return math_util.clamp_number(value, 0, MAX_BONUS, 0)
end

local function safe_get(force, ammo_category)
  local ok, result = pcall(function()
    return force.get_ammo_damage_modifier(ammo_category)
  end)
  if not ok then
    return nil
  end
  return result or 0
end

local function safe_set(force, ammo_category, value)
  return pcall(function()
    force.set_ammo_damage_modifier(ammo_category, value)
  end)
end

function M.apply(player, old, new)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local old_bonus = clamp_slider(old)
  local new_bonus = clamp_slider(new)
  local delta = new_bonus - old_bonus
  if delta == 0 then
    return
  end

  local force = player.force
  local applied_count = 0

  for _, ammo_category in ipairs(AMMO_CATEGORIES) do
    local current = safe_get(force, ammo_category)
    if current ~= nil then
      local result = math_util.max(MIN_MODIFIER, current + delta)
      local ok_set = safe_set(force, ammo_category, result)
      if ok_set then
        applied_count = applied_count + 1
      end
    end
  end

  if applied_count == 0 then
    player.print({"facc.runtime-compat-error", "slider_ammo_damage_boost"})
  end
end

return M
