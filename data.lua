-- data.lua
-- Registers FACC’s custom input (CTRL + .) and the new Legendary Upgrader tool & shortcut.

-- 1) FACC custom-input registration
data:extend({
  {
    type = "custom-input",
    name = "facc_toggle_gui",
    key_sequence = "CONTROL + PERIOD",
    consuming = "game-only",
    localised_name = {"controls.facc_toggle_gui"},
    localised_description = {"controls.facc_toggle_gui_description"}
  }
})

-- 2) Legendary Upgrader selection-tool & shortcut
local sounds = require("__base__.prototypes.item_sounds")

data:extend({

  ---------------------------------------------------------------------------
  -- Selection tool: drag-select an area to upgrade all entities to legendary
  ---------------------------------------------------------------------------
  {
    type                     = "selection-tool",
    name                     = "facc_legendary_upgrader",
    localised_name           = {"facc.legendary-upgrader-name"},
    localised_description    = {"facc.legendary-upgrader-desc"},
    icons = {
      { icon = "__factorio-admin-command-center__/graphics/icons/legendary-upgrade-planner.png" }
    },
    flags                    = {"only-in-cursor", "not-stackable", "spawnable"},
    subgroup                 = "tool",
    order                    = "c[admin]-d[legendary-upgrader]",
    inventory_move_sound     = sounds.planner_inventory_move,
    pick_sound               = sounds.planner_inventory_pickup,
    drop_sound               = sounds.planner_inventory_move,
    stack_size               = 1,
    draw_label_for_cursor_render = true,
    skip_fog_of_war          = true,

    -- Primary drag action
    select = {
      border_color    = {0, 200, 0},
      mode            = {"upgrade"},
      cursor_box_type = "not-allowed",
      started_sound   = { filename = "__core__/sound/upgrade-select-start.ogg" },
      ended_sound     = { filename = "__core__/sound/upgrade-select-end.ogg" }
    },

    -- Alt-drag (right button) does nothing
    alt_select = {
      border_color    = {0, 0, 0, 0},
      mode            = {"nothing"},
      cursor_box_type = "not-allowed"
    },

    -- Secondary drag action (after holding Shift, etc)
    reverse_select = {
      border_color    = {0, 200, 0},
      mode            = {"upgrade"},
      cursor_box_type = "not-allowed"
    },

    -- Alt + secondary drag also does nothing
    reverse_alt_select = {
      border_color    = {0, 0, 0, 0},
      mode            = {"nothing"},
      cursor_box_type = "not-allowed"
    }
  },

  ---------------------------------------------------------------------------
  -- Toolbar shortcut: gives the player the Legendary Upgrader item
  ---------------------------------------------------------------------------
  {
    type                   = "shortcut",
    name                   = "facc_give_legendary_upgrader",
    localised_name         = {"facc.legendary-upgrader-shortcut"},
    localised_description  = {"facc.legendary-upgrader-shortcut-desc"},
    action                 = "lua",
    technology_to_unlock   = "construction-robotics",
    item_to_spawn          = "facc_legendary_upgrader",
    style                  = "green",
    icon                   = "__factorio-admin-command-center__/graphics/icons/shortcut-toolbar/mip/legendary-upgrade-planner-x56.png",
    icon_size              = 56,
    small_icon             = "__factorio-admin-command-center__/graphics/icons/shortcut-toolbar/mip/legendary-upgrade-planner-x24.png",
    small_icon_size        = 24
  }

})
