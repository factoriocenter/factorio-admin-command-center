-- settings.lua
-- Startup settings for the Factorio Admin Command Center (FACC)

data:extend({
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
  {
    type = "string-setting",
    name = "facc-infinite-resources-multiplier",
    setting_type = "startup",
    default_value = "1x",
    allowed_values = {"1x", "2x", "5x", "10x", "20x", "50x"},
    order = "e",
    per_user = false,
    localised_name = {"mod-setting-name.facc-infinite-resources-multiplier"},
    localised_description = {"mod-setting-description.facc-infinite-resources-multiplier"}
  },
  {
    -- Disable automatic resource regeneration when infinite-resources setting changes
    type = "bool-setting",
    name = "facc-disable-auto-resource-regeneration",
    setting_type = "startup",
    default_value = false,
    order = "f",
    per_user = false,
    localised_name = {"mod-setting-name.facc-disable-auto-resource-regeneration"},
    localised_description = {"mod-setting-description.facc-disable-auto-resource-regeneration"}
  }
})
