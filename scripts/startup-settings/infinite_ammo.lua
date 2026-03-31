-- scripts/startup-settings/infinite_ammo.lua
-- Removes ammo consumption from any weapon definition by forcing:
--   • BaseAttackParameters.ammo_consumption_modifier = 0
--   • AmmoType.consumption_modifier = 0
--
-- We intentionally scan all prototype families because concrete turret types
-- are split (ammo-turret, artillery-turret, etc.) and mods can add more.

local function patch_ammo_type(ammo_type)
  if type(ammo_type) ~= "table" then
    return
  end

  -- Single AmmoType object
  if ammo_type.action ~= nil
      or ammo_type.target_type ~= nil
      or ammo_type.source_type ~= nil
      or ammo_type.energy_consumption ~= nil
      or ammo_type.consumption_modifier ~= nil then
    ammo_type.consumption_modifier = 0
    return
  end

  -- Fallback for list-like ammo_type tables used by some prototypes/mods
  for _, entry in pairs(ammo_type) do
    if type(entry) == "table" then
      entry.consumption_modifier = 0
    end
  end
end

local function patch_attack_parameters(attack_parameters)
  if type(attack_parameters) ~= "table" then
    return
  end

  attack_parameters.ammo_consumption_modifier = 0
  patch_ammo_type(attack_parameters.ammo_type)
end

local seen = {}
local function patch_recursive(tbl)
  if type(tbl) ~= "table" or seen[tbl] then
    return
  end
  seen[tbl] = true

  for key, value in pairs(tbl) do
    if type(value) == "table" then
      if key == "attack_parameters" or key == "revenge_attack_parameters" then
        patch_attack_parameters(value)
      end
      patch_recursive(value)
    end
  end
end

for _, prototypes in pairs(data.raw) do
  if type(prototypes) == "table" then
    for _, prototype in pairs(prototypes) do
      if type(prototype) == "table" then
        patch_recursive(prototype)
      end
    end
  end
end
