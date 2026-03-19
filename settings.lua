-- settings.lua
-- Mod settings for the Factorio Admin Command Center (FACC)
data:extend({
  -- Startup settings (require game restart)
  {
    type = "bool-setting",
    name = "facc-show-cheat-tab",
    setting_type = "startup",
    default_value = false,
    order = "a",
    per_user = false,
    localised_name = {"mod-setting-name.facc-show-cheat-tab"},
    localised_description = {"mod-setting-description.facc-show-cheat-tab"}
  },
  {
    type = "bool-setting",
    name = "facc-enable-achievement-overrides",
    setting_type = "startup",
    default_value = false,
    order = "b",
    per_user = false,
    localised_name = {"mod-setting-name.facc-enable-achievement-overrides"},
    localised_description = {"mod-setting-description.facc-enable-achievement-overrides"}
  },
  {
    type = "bool-setting",
    name = "facc-internal-names",
    setting_type = "startup",
    default_value = false,
    order = "c",
    per_user = false,
    localised_name = {"mod-setting-name.facc-internal-names"},
    localised_description = {"mod-setting-description.facc-internal-names"}
  },
  {
    type = "bool-setting",
    name = "facc-infinite-resources",
    setting_type = "startup",
    default_value = false,
    order = "d",
    per_user = false,
    localised_name = {"mod-setting-name.facc-infinite-resources"},
    localised_description = {"mod-setting-description.facc-infinite-resources"}
  },
  -- NEW: Separate multipliers for solid and fluid resources
  {
    type = "string-setting",
    name = "facc-infinite-resources-multiplier-solid",
    setting_type = "startup",
    default_value = "1x",
    allowed_values = {"1x", "2x", "5x", "10x", "20x", "50x"},
    order = "e1",
    per_user = false,
    localised_name = {"mod-setting-name.facc-infinite-resources-multiplier-solid"},
    localised_description = {"mod-setting-description.facc-infinite-resources-multiplier-solid"}
  },
  {
    type = "string-setting",
    name = "facc-infinite-resources-multiplier-fluid",
    setting_type = "startup",
    default_value = "1x",
    allowed_values = {"1x", "2x", "5x", "10x", "20x", "50x"},
    order = "e2",
    per_user = false,
    localised_name = {"mod-setting-name.facc-infinite-resources-multiplier-fluid"},
    localised_description = {"mod-setting-description.facc-infinite-resources-multiplier-fluid"}
  },
  {
    type = "bool-setting",
    name = "facc-instant-mining-drills",
    setting_type = "startup",
    default_value = false,
    order = "g",
    per_user = false,
    localised_name = {"mod-setting-name.facc-instant-mining-drills"},
    localised_description = {"mod-setting-description.facc-instant-mining-drills"}
  },
  {
    type = "bool-setting",
    name = "facc-instant-crafting-machines",
    setting_type = "startup",
    default_value = false,
    order = "h",
    per_user = false,
    localised_name = {"mod-setting-name.facc-instant-crafting-machines"},
    localised_description = {"mod-setting-description.facc-instant-crafting-machines"}
  },
  -- Map settings (no restart, affect the current save)
  {
    -- Disable automatic resource regeneration when infinite-resources setting changes
    type = "bool-setting",
    name = "facc-enable-auto-resource-regeneration",
    setting_type = "runtime-global",
    default_value = false,
    order = "f",
    per_user = false,
    localised_name = {"mod-setting-name.facc-enable-auto-resource-regeneration"},
    localised_description = {"mod-setting-description.facc-enable-auto-resource-regeneration"}
  },
  -- Player settings (no restart, per-player preference)
  {
    type = "bool-setting",
    name = "facc-enable-background-optimization",
    setting_type = "runtime-global",
    default_value = false,
    order = "i",
    localised_name = {"mod-setting-name.facc-enable-background-optimization"},
    localised_description = {"mod-setting-description.facc-enable-background-optimization"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-enabled",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j1",
    localised_name = {"mod-setting-name.facc-stats-hud-enabled"},
    localised_description = {"mod-setting-description.facc-stats-hud-enabled"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-research-eta",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j3",
    localised_name = {"mod-setting-name.facc-stats-hud-show-research-eta"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-research-eta"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-coordinates",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j4",
    localised_name = {"mod-setting-name.facc-stats-hud-show-coordinates"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-coordinates"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-distance-from-point",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j5",
    localised_name = {"mod-setting-name.facc-stats-hud-show-distance-from-point"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-distance-from-point"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-evolution",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j8",
    localised_name = {"mod-setting-name.facc-stats-hud-show-evolution"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-evolution"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-pollution",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j9",
    localised_name = {"mod-setting-name.facc-stats-hud-show-pollution"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-pollution"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-playtime",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j10",
    localised_name = {"mod-setting-name.facc-stats-hud-show-playtime"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-playtime"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-playtime-days",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j11",
    localised_name = {"mod-setting-name.facc-stats-hud-show-playtime-days"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-playtime-days"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-daytime",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j12",
    localised_name = {"mod-setting-name.facc-stats-hud-show-daytime"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-daytime"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-movement-speed",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j13",
    localised_name = {"mod-setting-name.facc-stats-hud-show-movement-speed"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-movement-speed"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-player-max-speed",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j14",
    localised_name = {"mod-setting-name.facc-stats-hud-show-player-max-speed"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-player-max-speed"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-vehicle-max-speed",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j15",
    localised_name = {"mod-setting-name.facc-stats-hud-show-vehicle-max-speed"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-vehicle-max-speed"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-handcraft-timer",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j16",
    localised_name = {"mod-setting-name.facc-stats-hud-show-handcraft-timer"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-handcraft-timer"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-show-jetpack-fuel",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j17",
    localised_name = {"mod-setting-name.facc-stats-hud-show-jetpack-fuel"},
    localised_description = {"mod-setting-description.facc-stats-hud-show-jetpack-fuel"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-offset-preset-one-info",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j18",
    localised_name = {"mod-setting-name.facc-stats-hud-offset-preset-one-info"},
    localised_description = {"mod-setting-description.facc-stats-hud-offset-preset-one-info"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-offset-preset-two-infos",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j19",
    localised_name = {"mod-setting-name.facc-stats-hud-offset-preset-two-infos"},
    localised_description = {"mod-setting-description.facc-stats-hud-offset-preset-two-infos"}
  },
  {
    type = "bool-setting",
    name = "facc-stats-hud-offset-preset-three-infos",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j20",
    localised_name = {"mod-setting-name.facc-stats-hud-offset-preset-three-infos"},
    localised_description = {"mod-setting-description.facc-stats-hud-offset-preset-three-infos"}
  }
})
-- NOTE:
-- We intentionally did not re-declare the legacy single multiplier
-- "facc-infinite-resources-multiplier". Existing saves that still carry it
-- will be read at runtime/data stage (as a fallback) if present in the save.
