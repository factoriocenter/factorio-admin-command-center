-- settings.lua
-- Startup settings for the Factorio Admin Command Center (FACC)

data:extend({
  {
    type = "bool-setting",
    name = "facc-show-cheat-tab",
    setting_type = "startup",
    default_value = true,
    order = "e",
    per_user = false,
    localised_name = {"mod-setting-name.facc-show-cheat-tab"},
    localised_description = {"mod-setting-description.facc-show-cheat-tab"}
  },
  {
    type = "bool-setting",
    name = "facc-internal-names",
    setting_type = "startup",
    default_value = false,
    order = "f",
    per_user = false,
    localised_name = {"mod-setting-name.facc-internal-names"},
    localised_description = {"mod-setting-description.facc-internal-names"}
  },
})
