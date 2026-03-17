-- scripts/gui/main_gui.lua
-- Main GUI for the Factorio Admin Command Center (FACC)
-- Implements a tabbed interface with persistent state, DLC/mod checks, and safe restoration on load.
-- Added tooltip support: if an element has a `tooltip` field, an info icon will appear next to its label.

local M = {}
local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")
local gui_events = require("scripts/events/gui_events")

--------------------------------------------------------------------------------
-- Mod detection
--------------------------------------------------------------------------------
local quality_enabled   = script.active_mods["quality"]   ~= nil
local space_age_enabled = script.active_mods["space-age"] ~= nil
-- Disable “Increase Resources” when infinite resources is active
local infinite_resources_enabled = settings.startup["facc-infinite-resources"]
    and settings.startup["facc-infinite-resources"].value

--------------------------------------------------------------------------------
-- UI layout constants
--------------------------------------------------------------------------------
local SPACING = 12
local PLANET_TELEPORT_PREFIX = "facc_teleport_planet__"

local CONFIRM_BUTTON_EXCLUDED = {
  facc_set_platform_distance = true,
  facc_set_game_speed = true,
  facc_set_crafting_speed = true,
  facc_set_mining_speed = true,
  facc_run_faster = true,
  facc_increase_robot_speed = true,
  facc_build_distance = true,
  facc_reach_distance = true,
  facc_resource_reach_distance = true,
  facc_item_drop_distance = true,
  facc_item_pickup_distance = true,
  facc_loot_pickup_distance = true,
  facc_ammo_damage_boost = true,
  facc_turret_damage_boost = true
}

--------------------------------------------------------------------------------
-- Tab definitions (one per folder/tag)
--------------------------------------------------------------------------------
local TAB_ORDER = {
  "cheats",
  "armor",
  "blueprints",
  "character",
  -- "circuit-network",
  "combat",
  "enemies",
  "environment",
  -- "fluids",
  "logistic-network",
  -- "logistics",
  "manufacturing",
  "mining",
  "planets",
  "power",
  -- "storage",
  "trains",
  "transportation"
}

local TABS = {
  armor = {
    label    = {"facc.tab-armor"},
    elements = {
      {
        name    = "facc_create_full_armor",
        caption = {"facc.create-full-armor"},
        tooltip = {"tooltip.create-full-armor"}
      }
    }
  },
  blueprints = {
    label    = {"facc.tab-blueprints"},
    elements = {
      {
        name    = "facc_instant_blueprint_building",
        caption = {"facc.instant-blueprint-building"},
        tooltip = {"tooltip.instant-blueprint-building"},
        switch  = true
      },
      {
        name    = "facc_instant_deconstruction",
        caption = {"facc.instant-deconstruction"},
        tooltip = {"tooltip.instant-deconstruction"},
        switch  = true
      },
      {
        name    = "facc_instant_upgrading",
        caption = {"facc.instant-upgrading"},
        tooltip = {"tooltip.instant-upgrading"},
        switch  = true
    },
      {
        name    = "facc_instant_rail_planner",
        caption = {"facc.instant-rail-planner"},
        tooltip = {"tooltip.instant-rail-planner"},
        switch  = true
      },
      {
        name    = "facc_ghost_on_death",
        caption = {"facc.ghost-on-death"},
        tooltip = {"tooltip.ghost-on-death"}
      },
      {
        name    = "facc_build_all_ghosts",
        caption = {"facc.build-all-ghosts"},
        tooltip = {"tooltip.build-all-ghosts"}
      },
      {
        name    = "facc_repair_rebuild",
        caption = {"facc.repair-rebuild"},
        tooltip = {"tooltip.repair-rebuild"}
      },
      {
        name    = "facc_remove_decon",
        caption = {"facc.remove-decon"},
        tooltip = {"tooltip.remove-decon"}
      },
      {
        name    = "facc_upgrade_blueprints",
        caption = {"facc.upgrade-blueprints"},
        tooltip = {"tooltip.upgrade-blueprints"}
      },
      {
        name    = "facc_convert_to_legendary",
        caption = {"facc.convert-to-legendary"},
        tooltip = {"tooltip.convert-to-legendary"},
        slider  = { name="slider_convert_to_legendary", min=1, max=150, default=75 }
      },
    }
  },
  character = {
    label    = {"facc.tab-character"},
    elements = {
      {
        name    = "facc_ghost_mode",
        caption = {"facc.ghost-mode"},
        tooltip = {"tooltip.ghost-mode"},
        switch  = true
      },
      {
        name    = "facc_invincible_player",
        caption = {"facc.invincible-player"},
        tooltip = {"tooltip.invincible-player"},
        switch  = true
      },
      {
        name    = "facc_repair_mined_item",
        caption = {"facc.repair-mined-item"},
        tooltip = {"tooltip.repair-mined-item"},
        switch  = true
      },
      {
        name    = "facc_delete_ownerless",
        caption = {"facc.delete-ownerless"},
        tooltip = {"tooltip.delete-ownerless"}
      },
      {
        name    = "facc_convert_inventory",
        caption = {"facc.convert-inventory"},
        tooltip = {"tooltip.convert-inventory"}
      },
      {
        name    = "facc_run_faster",
        caption = {"facc.run-faster"},
        tooltip = {"tooltip.run-faster"},
        slider  = { name="slider_run_faster", min=0, max=10, default=0 }
      },
      {
        name    = "facc_build_distance",
        caption = {"facc.build-distance"},
        tooltip = {"tooltip.build-distance"},
        slider  = { name="slider_build_distance", min=0, max=100, default=0 }
      },
      {
        name    = "facc_reach_distance",
        caption = {"facc.reach-distance"},
        tooltip = {"tooltip.reach-distance"},
        slider  = { name="slider_reach_distance", min=0, max=100, default=0 }
      },
      {
        name    = "facc_resource_reach_distance",
        caption = {"facc.resource-reach-distance"},
        tooltip = {"tooltip.resource-reach-distance"},
        slider  = { name="slider_resource_reach_distance", min=0, max=100, default=0 }
      },
      {
        name    = "facc_item_drop_distance",
        caption = {"facc.item-drop-distance"},
        tooltip = {"tooltip.item-drop-distance"},
        slider  = { name="slider_item_drop_distance", min=0, max=100, default=0 }
      },
      {
        name    = "facc_item_pickup_distance",
        caption = {"facc.item-pickup-distance"},
        tooltip = {"tooltip.item-pickup-distance"},
        slider  = { name="slider_item_pickup_distance", min=0, max=100, default=0 }
      },
      {
        name    = "facc_loot_pickup_distance",
        caption = {"facc.loot-pickup-distance"},
        tooltip = {"tooltip.loot-pickup-distance"},
        slider  = { name="slider_loot_pickup_distance", min=0, max=100, default=0 }
      }
    }
  },
  cheats = {
    label    = {"facc.tab-cheats"},
    elements = {
      {
        name    = "facc_cheat_mode",
        caption = {"facc.cheat-mode"},
        tooltip = {"tooltip.cheat-mode"},
        switch  = true
      },
      {
        name    = "facc_auto_instant_research",
        caption = {"facc.auto-instant-research"},
        tooltip = {"tooltip.auto-instant-research"},
        slider  = { name="slider_auto_instant_research", min=1, max=300, default=1 },
        switch  = true
      },
      {
        name    = "facc_toggle_editor",
        caption = {"facc.toggle-editor"},
        tooltip = {"tooltip.toggle-editor"}
      },
      {
        name    = "facc_console",
        caption = {"facc.console"},
        tooltip = {"tooltip.console"}
      },
      {
        name    = "facc_unlock_recipes",
        caption = {"facc.unlock-recipes"},
        tooltip = {"tooltip.unlock-recipes"}
      },
      {
        name    = "facc_unlock_technologies",
        caption = {"facc.unlock-technologies"},
        tooltip = {"tooltip.unlock-technologies"}
      },
      {
        name    = "facc_high_infinite_research_levels",
        caption = {"facc.high_infinite_research_levels"},
        tooltip = {"tooltip.high_infinite_research_levels"}
      },
      {
        name    = "facc_add_infinite_research_levels",
        caption = {"facc.add_infinite_research_levels"},
        tooltip = {"tooltip.add_infinite_research_levels"}
      },
      {
        name    = "facc_insert_coins",
        caption = {"facc.insert-coins"},
        tooltip = {"tooltip.insert-coins"}
      },
      {
        name    = "facc_set_game_speed",
        caption = {"facc.set-game-speed"},
        tooltip = {"tooltip.set-game-speed"},
        slider  = { name="slider_set_game_speed", min=1, max=9, default=3 }
      }
    }
  },
  combat = {
    label    = {"facc.tab-combat"},
    elements = {
      {
        name    = "facc_disable_friendly_fire",
        caption = {"facc.disable-friendly-fire"},
        tooltip = {"tooltip.disable-friendly-fire"},
        switch  = true
      },
      {
        name    = "facc_indestructible_builds",
        caption = {"facc.indestructible-builds"},
        tooltip = {"tooltip.indestructible-builds"},
        switch  = true
      },
      {
        name    = "facc_peaceful_mode",
        caption = {"facc.peaceful-mode"},
        tooltip = {"tooltip.peaceful-mode"},
        switch  = true
      },
      {
        name    = "facc_indestructible_builds_permanent",
        caption = {"facc.indestructible-builds_permanent"},
        tooltip = {"tooltip.indestructible-builds_permanent"},
      },
      {
        name    = "facc_ammo_turrets",
        caption = {"facc.ammo-turrets"},
        tooltip = {"tooltip.ammo-turrets"}
      },
      {
        name    = "facc_ammo_damage_boost",
        caption = {"facc.ammo-damage-boost"},
        tooltip = {"tooltip.ammo-damage-boost"},
        slider  = { name="slider_ammo_damage_boost", min=0, max=1000, default=0 }
      },
      {
        name    = "facc_turret_damage_boost",
        caption = {"facc.turret-damage-boost"},
        tooltip = {"tooltip.turret-damage-boost"},
        slider  = { name="slider_turret_damage_boost", min=0, max=1000, default=0 }
      }
    }
  },
  enemies = {
    label    = {"facc.tab-enemies"},
    elements = {
      {
        name    = "facc_enemy_expansion",
        caption = {"facc.enemy-expansion"},
        tooltip = {"tooltip.enemy-expansion"},
        switch  = true
      },
      {
        name    = "facc_remove_nests",
        caption = {"facc.remove-nests"},
        tooltip = {"tooltip.remove-nests"},
        slider  = { name="slider_remove_nests", min=1, max=150, default=50 }
      }
    }
  },
  environment = {
    label    = {"facc.tab-environment"},
    elements = {
      {
        name    = "facc_surface_freeze_daytime",
        caption = {"facc.surface-freeze-daytime"},
        tooltip = {"tooltip.surface-freeze-daytime"},
        switch  = true
      },
      {
        name    = "facc_surface_peaceful_mode",
        caption = {"facc.surface-peaceful-mode"},
        tooltip = {"tooltip.surface-peaceful-mode"},
        switch  = true
      },
      {
        name    = "facc_surface_no_enemies_mode",
        caption = {"facc.surface-no-enemies"},
        tooltip = {"tooltip.surface-no-enemies"},
        switch  = true
      },
      {
        name    = "facc_always_day",
        caption = {"facc.always-day"},
        tooltip = {"tooltip.always-day"},
        switch  = true
      },
      {
        name    = "facc_disable_pollution",
        caption = {"facc.disable-pollution"},
        tooltip = {"tooltip.disable-pollution"},
        switch  = true
      },
      {
        name    = "facc_auto_clean_pollution",
        caption = {"facc.auto-clean-pollution"},
        tooltip = {"tooltip.auto-clean-pollution"},
        slider  = { name="slider_auto_clean_pollution", min=1, max=300, default=1 },
        switch  = true
      },
      {
        name    = "facc_surface_daytime_midday",
        caption = {"facc.surface-daytime-midday"},
        tooltip = {"tooltip.surface-daytime-midday"}
      },
      {
        name    = "facc_surface_daytime_midnight",
        caption = {"facc.surface-daytime-midnight"},
        tooltip = {"tooltip.surface-daytime-midnight"}
      },
      {
        name    = "facc_remove_pollution",
        caption = {"facc.remove-pollution"},
        tooltip = {"tooltip.remove-pollution"}
      },
      {
        name    = "facc_hide_map",
        caption = {"facc.hide-map"},
        tooltip = {"tooltip.hide-map"}
      },
      {
        name    = "facc_remove_ground_items",
        caption = {"facc.remove-ground-items"},
        tooltip = {"tooltip.remove-ground-items"}
      },
      {
        name    = "facc_surface_daytime",
        caption = {"facc.surface-daytime"},
        tooltip = {"tooltip.surface-daytime"},
        slider  = { name="slider_surface_daytime", min=0, max=100, default=50 }
      },
      {
        name    = "facc_surface_pressure",
        caption = {"facc.surface-pressure"},
        tooltip = {"tooltip.surface-pressure"},
        slider  = { name="slider_surface_pressure", min=0, max=2000, default=1000 }
      },
      {
        name    = "facc_surface_magnetic_field",
        caption = {"facc.surface-magnetic-field"},
        tooltip = {"tooltip.surface-magnetic-field"},
        slider  = { name="slider_surface_magnetic_field", min=0, max=2000, default=90 }
      },
      {
        name    = "facc_surface_gravity",
        caption = {"facc.surface-gravity"},
        tooltip = {"tooltip.surface-gravity"},
        slider  = { name="slider_surface_gravity", min=0, max=2000, default=10 }
      },
      {
        name    = "facc_reveal_map",
        caption = {"facc.reveal-map"},
        tooltip = {"tooltip.reveal-map"},
        slider  = { name="slider_reveal_map", min=1, max=150, default=150 }
      },
      {
        name    = "facc_remove_cliffs",
        caption = {"facc.remove-cliffs"},
        tooltip = {"tooltip.remove-cliffs"},
        slider  = { name="slider_remove_cliffs", min=1, max=150, default=50 }
      }
    }
  },
  ["logistic-network"] = {
    label    = {"facc.tab-logistic-network"},
    elements = {
      {
        name    = "facc_instant_request",
        caption = {"facc.instant-request"},
        tooltip = {"tooltip.instant-request"},
        switch  = true
      },
      {
        name    = "facc_instant_trash",
        caption = {"facc.instant-trash"},
        tooltip = {"tooltip.instant-trash"},
        switch  = true
      },
      {
        name    = "facc_add_robots",
        caption = {"facc.add-robots"},
        tooltip = {"tooltip.add-robots"}
      },
      {
        name    = "facc_increase_robot_speed",
        caption = {"facc.increase-robot-speed"},
        tooltip = {"tooltip.increase-robot-speed"},
        slider  = { name="slider_increase_robot_speed", min=0, max=50, default=0 }
      }
    }
  },
  manufacturing = {
    label    = {"facc.tab-manufacturing"},
    elements = {
      {
        name    = "facc_set_crafting_speed",
        caption = {"facc.set-crafting-speed"},
        tooltip = {"tooltip.set-crafting-speed"},
        slider  = { name="slider_set_crafting_speed", min=0, max=1000, default=0 }
      }
    }
  },
  mining = {
    label    = {"facc.tab-mining"},
    elements = {
      {
        name    = "facc_toggle_minable",
        caption = {"facc.toggle-minable"},
        tooltip = {"tooltip.toggle-minable"},
        switch  = true
      },
      {
        name    = "facc_non_minable_permanent",
        caption = {"facc.non-minable-permanent"},
        tooltip = {"tooltip.non-minable-permanent"},
      },
      {
        name    = "facc_set_mining_speed",
        caption = {"facc.set-mining-speed"},
        tooltip = {"tooltip.set-mining-speed"},
        slider  = { name="slider_set_mining_speed", min=0, max=1000, default=0 }
      }
    }
  },
  planets = {
    label    = {"facc.tab-planets"},
    elements = {
      {
        name    = "facc_regenerate_resources",
        caption = {"facc.regenerate-resources"},
        tooltip = {"tooltip.regenerate-resources"}
      },
      {
        name    = "facc_increase_resources",
        caption = {"facc.increase-resources"},
        tooltip = {"tooltip.increase-resources"}
      },
      {
        name    = "facc_generate_planet_surfaces",
        caption = {"facc.generate-planet-surfaces"},
        tooltip = {"tooltip.generate-planet-surfaces"}
      }
    }
  },
  power = {
    label    = {"facc.tab-power"},
    elements = {
      {
        name    = "facc_recharge_energy",
        caption = {"facc.recharge-energy"},
        tooltip = {"tooltip.recharge-energy"}
      }
    }
  },
  trains = {
    label    = {"facc.tab-trains"},
    elements = {
      {
        name    = "facc_toggle_trains",
        caption = {"facc.trains-auto-mode"},
        tooltip = {"tooltip.trains-auto-mode"},
        switch  = true
      }
    }
  },
  transportation = {
    label    = {"facc.tab-transportation"},
    elements = {
      {
        name    = "facc_fill_platform_thrusters",
        caption = {"facc.fill-thrusters"},
        tooltip = {"tooltip.fill-thrusters"}
      },
      {
        name    = "facc_set_platform_distance",
        caption = {"facc.platform-distance"},
        tooltip = {"tooltip.platform-distance"},
        slider  = { name="slider_platform_distance", min=0.0, max=1.0, default=0.99 }
      }
    }
  }
}

--------------------------------------------------------------------------------
-- Persistent state schema (with version-mismatch check)
--------------------------------------------------------------------------------
function M.ensure_persistent_state()
  local s = flib_table.get_or_insert(storage, "facc_gui_state", {})
  if type(s) ~= "table" then
    s = {}
    storage.facc_gui_state = s
  end
  -- if old save's tab no longer exists, reset to "cheats"
  if not (s.tab and TABS[s.tab]) then s.tab = "cheats" end
  if type(s.sliders) ~= "table" then s.sliders = {} end
  if type(s.switches) ~= "table" then s.switches = {} end

  local old_long_reach = s.sliders["slider_long_reach"]
  if old_long_reach ~= nil then
    if s.sliders["slider_build_distance"] == nil then
      s.sliders["slider_build_distance"] = old_long_reach
    end
    if s.sliders["slider_reach_distance"] == nil then
      s.sliders["slider_reach_distance"] = old_long_reach
    end
    if s.sliders["slider_resource_reach_distance"] == nil then
      s.sliders["slider_resource_reach_distance"] = old_long_reach
    end
    if s.sliders["slider_item_drop_distance"] == nil then
      s.sliders["slider_item_drop_distance"] = old_long_reach
    end
    if s.sliders["slider_item_pickup_distance"] == nil then
      s.sliders["slider_item_pickup_distance"] = old_long_reach
    end
    if s.sliders["slider_loot_pickup_distance"] == nil then
      s.sliders["slider_loot_pickup_distance"] = old_long_reach
    end
  end

  if type(s.is_open) ~= "boolean" then s.is_open = false end
end

local function sync_surface_switch_states(player)
  if not (player and player.valid and player.surface and player.surface.valid) then
    return
  end
  M.ensure_persistent_state()

  local switches = storage.facc_gui_state.switches
  switches.facc_surface_freeze_daytime = player.surface.freeze_daytime == true
  switches.facc_surface_peaceful_mode = player.surface.peaceful_mode == true

  local ok, value = pcall(function()
    return player.surface.no_enemies_mode
  end)
  if ok then
    switches.facc_surface_no_enemies_mode = value == true
  end
end

--------------------------------------------------------------------------------
-- Save all slider values recursively
--------------------------------------------------------------------------------
local function save_all_sliders(element)
  if element.type == "slider" then
    storage.facc_gui_state.sliders[element.name] = element.slider_value
  end
  if element.children then
    for _, child in ipairs(element.children) do
      save_all_sliders(child)
    end
  end
end

--------------------------------------------------------------------------------
-- Feature enablement checks
--------------------------------------------------------------------------------
local function surface_supports_property(player, property_name)
  if not (player and player.valid and player.surface and player.surface.valid) then
    return false
  end
  local ok = pcall(player.surface.get_property, player.surface, property_name)
  return ok
end

local function surface_supports_no_enemies_mode(player)
  if not (player and player.valid and player.surface and player.surface.valid) then
    return false
  end
  local ok = pcall(function()
    return player.surface.no_enemies_mode
  end)
  return ok
end

local function is_feature_enabled(name, player)
  if string.sub(name, 1, #PLANET_TELEPORT_PREFIX) == PLANET_TELEPORT_PREFIX then
    local planet_name = string.sub(name, #PLANET_TELEPORT_PREFIX + 1)
    if planet_name == "nauvis" then
      return true
    end
    return space_age_enabled
  end
  if name == "facc_surface_no_enemies_mode" then
    return surface_supports_no_enemies_mode(player)
  end
  if name == "facc_surface_pressure" then
    return space_age_enabled and surface_supports_property(player, "pressure")
  end
  if name == "facc_surface_magnetic_field" then
    return space_age_enabled and surface_supports_property(player, "magnetic-field")
  end
  if name == "facc_surface_gravity" then
    return space_age_enabled and surface_supports_property(player, "gravity")
  end
  if name == "facc_set_platform_distance" then return space_age_enabled end
  if name == "facc_fill_platform_thrusters" then return space_age_enabled end
  if name == "facc_generate_planet_surfaces" then return space_age_enabled end
  if name == "facc_convert_inventory"
      or name == "facc_upgrade_blueprints"
      or name == "facc_convert_to_legendary" then
    return quality_enabled
  end
  return true
end

--------------------------------------------------------------------------------
-- Helper: render a function block (label/slider/switch/button)
--------------------------------------------------------------------------------
local function add_function_block(parent, elem, player)
  local enabled = is_feature_enabled(elem.name, player)
  local left_children = {}

  if elem.tooltip then
    left_children[#left_children + 1] = {
      type = "flow",
      direction = "horizontal",
      style_mods = {
        horizontal_spacing = 4,
        vertical_align = "center"
      },
      children = {
        { type = "label", caption = elem.caption },
        { type = "sprite", sprite = "info", tooltip = elem.tooltip }
      }
    }
  else
    left_children[#left_children + 1] = {
      type = "label",
      caption = elem.caption
    }
  end

  if elem.slider then
    local slider_name = elem.slider.name
    local init = storage.facc_gui_state.sliders[slider_name] or elem.slider.default
    local slider_children = {
      {
        type = "slider",
        name = slider_name,
        minimum_value = elem.slider.min,
        maximum_value = elem.slider.max,
        value = init,
        discrete_slider = true,
        style_mods = {
          horizontally_stretchable = true
        },
        handler = { [defines.events.on_gui_value_changed] = gui_events.handlers.slider }
      }
    }

    if slider_name ~= "slider_platform_distance" then
      local display_value = init
      if slider_name == "slider_set_game_speed" then
        local speeds = {0.25, 0.5, 1, 2, 4, 8, 16, 32, 64}
        display_value = speeds[init] or speeds[3]
      elseif slider_name == "slider_surface_daytime" then
        display_value = string.format("%.2f", (tonumber(init) or 50) / 100)
      end
      slider_children[#slider_children + 1] = {
        type = "textfield",
        name = slider_name .. "_value",
        text = tostring(display_value),
        numeric = true,
        read_only = true,
        style = "short_number_textfield",
        style_mods = {
          width = 40
        }
      }
    end

    left_children[#left_children + 1] = {
      type = "flow",
      direction = "horizontal",
      style_mods = {
        horizontal_spacing = SPACING,
        vertical_align = "center"
      },
      children = slider_children
    }
  end

  local row_children = {
    {
      type = "flow",
      direction = "vertical",
      style_mods = {
        vertical_spacing = SPACING,
        horizontally_stretchable = true
      },
      children = left_children
    }
  }

  if elem.switch then
    local state = storage.facc_gui_state.switches[elem.name] and "right" or "left"
    row_children[#row_children + 1] = {
      type = "flow",
      direction = "horizontal",
      style_mods = {
        horizontal_align = "right"
      },
      children = {
        {
          type = "switch",
          name = elem.name,
          switch_state = state,
          left_label_caption = {"facc.switch-off"},
          right_label_caption = {"facc.switch-on"},
          handler = { [defines.events.on_gui_switch_state_changed] = gui_events.handlers.switch }
        }
      }
    }
  elseif not CONFIRM_BUTTON_EXCLUDED[elem.name] then
    row_children[#row_children + 1] = {
      type = "flow",
      direction = "horizontal",
      style_mods = {
        horizontal_align = "right"
      },
      children = {
        {
          type = "sprite-button",
          name = elem.name,
          sprite = "utility.confirm_slot",
          style = "item_and_count_select_confirm",
          tooltip = {"facc.confirm-button"},
          handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
        }
      }
    }
  end

  local created = {}
  flib_gui.add(parent, {
    type = "flow",
    direction = "horizontal",
    style_mods = {
      horizontal_spacing = SPACING,
      vertical_align = "center"
    },
    children = row_children
  }, created)

  if elem.slider then
    local slider = created[elem.slider.name]
    if slider and slider.valid then
      slider.enabled = enabled
    end

    if elem.slider.name ~= "slider_platform_distance" then
      local box = created[elem.slider.name .. "_value"]
      if box and box.valid then
        box.enabled = false
      end
    end
  end

  if elem.switch then
    local sw = created[elem.name]
    if sw and sw.valid then
      sw.enabled = enabled
    end
  elseif not CONFIRM_BUTTON_EXCLUDED[elem.name] then
    local btn = created[elem.name]
    if btn and btn.valid then
      if infinite_resources_enabled and (elem.name == "facc_increase_resources" or elem.name == "facc_regenerate_resources") then
        btn.enabled = false
      elseif elem.name == "facc_ghost_on_death"
          and player
          and player.valid
          and player.force
          and player.force.technologies["construction-robotics"]
          and player.force.technologies["construction-robotics"].researched
      then
        btn.enabled = false
      else
        btn.enabled = enabled
      end
    end
  end
end

local function add_separator(parent)
  flib_gui.add(parent, {
    type = "line",
    direction = "horizontal",
    style_mods = {
      horizontally_stretchable = true
    }
  })
end

local function add_planet_teleport_blocks(parent, player)
  local planet_progress_order = {
    nauvis = 1,
    vulcanus = 2,
    fulgora = 3,
    gleba = 4,
    aquilo = 5
  }

  local known_planets = {
    nauvis = true,
    vulcanus = true,
    fulgora = true,
    gleba = true,
    aquilo = true
  }

  local planet_names = {"nauvis", "vulcanus", "fulgora", "gleba", "aquilo"}
  if game.planets then
    for name in pairs(game.planets) do
      if not known_planets[name] then
        planet_names[#planet_names + 1] = name
        known_planets[name] = true
      end
    end
  end

  table.sort(planet_names, function(a, b)
    local ia = planet_progress_order[a]
    local ib = planet_progress_order[b]
    if ia and ib then
      return ia < ib
    end
    if ia then
      return true
    end
    if ib then
      return false
    end
    return a < b
  end)

  local has_previous_elements = #parent.children > 0

  for _, planet_name in ipairs(planet_names) do
    local planet = game.planets and game.planets[planet_name]
    local display_name = string.upper(string.sub(planet_name, 1, 1)) .. string.sub(planet_name, 2)
    if planet and planet.valid and planet.prototype and planet.prototype.valid then
      display_name = planet.prototype.localised_name
    end

    if has_previous_elements then
      add_separator(parent)
    end

    add_function_block(parent, {
      name = PLANET_TELEPORT_PREFIX .. planet_name,
      caption = {"facc.teleport-to-planet", display_name},
      tooltip = {"tooltip.teleport-to-planet"}
    }, player)

    has_previous_elements = true
  end
end

--------------------------------------------------------------------------------
-- Build & display the GUI
--------------------------------------------------------------------------------
local function open_gui(player)
  if not (player and player.valid) then
    return
  end
  if not (not game.is_multiplayer() or player.admin) then
    player.print({"facc.not-allowed"})
    return
  end
  M.ensure_persistent_state()
  sync_surface_switch_states(player)

  if player.gui.screen["facc_main_frame"] then
    player.gui.screen["facc_main_frame"].destroy()
  end

  local elems, frame = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "facc_main_frame",
    direction = "vertical",
    children = {
      {
        type = "flow",
        name = "title_flow",
        direction = "horizontal",
        drag_target = "facc_main_frame",
        style_mods = {
          horizontal_spacing = SPACING,
          horizontally_stretchable = true,
          vertical_align = "center"
        },
        children = {
          {
            type = "label",
            name = "facc_main_title",
            caption = {"facc.main-title"},
            style = "frame_title",
            drag_target = "facc_main_frame"
          },
          {
            type = "empty-widget",
            name = "facc_drag_space",
            style = "draggable_space_header",
            style_mods = {
              horizontally_stretchable = true,
              vertically_stretchable = true
            },
            drag_target = "facc_main_frame"
          },
          {
            type = "sprite-button",
            name = "facc_close_main_gui",
            sprite = "utility/close",
            style = "frame_action_button",
            tooltip = {"facc.close-menu"},
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          }
        }
      },
      {
        type = "flow",
        name = "facc_container",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = SPACING
        },
        children = {
          {
            type = "frame",
            name = "facc_menu_frame",
            style = "inside_shallow_frame",
            direction = "vertical",
            style_mods = {
              minimal_width = 200,
              maximal_width = 200,
              vertically_stretchable = true,
              padding = SPACING
            },
            children = {
              {
                type = "scroll-pane",
                name = "facc_menu_pane",
                direction = "vertical",
                elem_mods = {
                  horizontal_scroll_policy = "never",
                  vertical_scroll_policy = "auto"
                },
                style_mods = {
                  vertically_stretchable = true
                },
                children = {
                  {
                    type = "list-box",
                    name = "facc_menu_list",
                    handler = { [defines.events.on_gui_selection_state_changed] = gui_events.handlers.menu_selection },
                    style_mods = {
                      horizontally_stretchable = true,
                      minimal_width = 180
                    }
                  }
                }
              }
            }
          },
          {
            type = "frame",
            name = "facc_content_outer",
            style = "inside_shallow_frame",
            direction = "vertical",
            style_mods = {
              horizontally_stretchable = true,
              minimal_width = 800,
              minimal_height = 600
            },
            children = {
              {
                type = "frame",
                name = "facc_subheader_frame",
                style = "subheader_frame",
                direction = "horizontal",
                style_mods = {
                  horizontally_stretchable = true
                },
                children = {
                  {
                    type = "label",
                    name = "facc_subheader_label",
                    caption = TABS[storage.facc_gui_state.tab].label,
                    style = "heading_2_label"
                  }
                }
              },
              {
                type = "scroll-pane",
                name = "facc_content_pane",
                direction = "vertical",
                elem_mods = {
                  horizontal_scroll_policy = "never",
                  vertical_scroll_policy = "auto"
                },
                style_mods = {
                  vertically_stretchable = true,
                  padding = SPACING
                }
              }
            }
          }
        }
      }
    }
  })
  frame.auto_center = true

  local list = elems.facc_menu_list
  for _, key in ipairs(TAB_ORDER) do
    list.add_item(TABS[key].label)
  end
  for i, key in ipairs(TAB_ORDER) do
    if key == storage.facc_gui_state.tab then
      list.selected_index = i
      break
    end
  end

  local content_pane = elems.facc_content_pane

  for _, key in ipairs(TAB_ORDER) do
    local _, sec = flib_gui.add(content_pane, {
      type = "flow",
      name = "facc_content_" .. key,
      direction = "vertical",
      style_mods = {
        vertical_spacing = SPACING
      }
    })
    sec.visible = (key == storage.facc_gui_state.tab)
    for i, elem in ipairs(TABS[key].elements) do
      if i > 1 then
        add_separator(sec)
      end
      add_function_block(sec, elem, player)
    end

    if key == "planets" then
      add_planet_teleport_blocks(sec, player)
    end
  end
end

local function apply_tab_to_frame(main, new_tab)
  local container = main and main.children and main.children[2]
  local outer = container and container["facc_content_outer"]
  local pane = outer and outer["facc_content_pane"]
  if pane then
    for _, key in ipairs(TAB_ORDER) do
      local section = pane["facc_content_" .. key]
      if section and section.valid then
        section.visible = (key == new_tab)
      end
    end
  end

  local sub = outer and outer["facc_subheader_frame"]
  local lbl = sub and sub["facc_subheader_label"]
  if lbl and lbl.valid then
    lbl.caption = TABS[new_tab].label
  end
end

function M.handle_tab_selection(player, selected_index)
  M.ensure_persistent_state()
  if not (selected_index and TAB_ORDER[selected_index]) then return end
  local new_tab = TAB_ORDER[selected_index]
  storage.facc_gui_state.tab = new_tab

  local main = player and player.valid and player.gui.screen["facc_main_frame"] or nil
  if not (main and main.valid) then
    open_gui(player)
    return
  end
  apply_tab_to_frame(main, new_tab)
end

function M.restore_open_gui_for_all_players()
  M.ensure_persistent_state()
  if not storage.facc_gui_state.is_open then return end
  flib_table.for_each(game.players, function(player)
    if not game.is_multiplayer() or player.admin then
      open_gui(player)
    end
  end)
end

function M.toggle_main_gui(player)
  if not (player and player.valid) then return end
  M.ensure_persistent_state()
  local frame = player.gui.screen["facc_main_frame"]
  if frame then
    local container = frame.children[2]
    local outer     = container and container["facc_content_outer"]
    local pane      = outer and outer["facc_content_pane"]
    if pane then save_all_sliders(pane) end
    frame.destroy()
    storage.facc_gui_state.is_open = false
  else
    open_gui(player)
    storage.facc_gui_state.is_open = true
  end
end

function M.refresh_open_gui(player)
  if not (player and player.valid) then return end
  M.ensure_persistent_state()

  local frame = player.gui.screen["facc_main_frame"]
  if not (frame and frame.valid) then return end

  local container = frame.children[2]
  local outer = container and container["facc_content_outer"]
  local pane = outer and outer["facc_content_pane"]
  if pane then
    save_all_sliders(pane)
  end

  frame.destroy()
  open_gui(player)
  storage.facc_gui_state.is_open = true
end

gui_events.set_main_gui_api(M)

return M
