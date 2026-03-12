-- scripts/gui/main_gui.lua
-- Main GUI for the Factorio Admin Command Center (FACC)
-- Implements a tabbed interface with persistent state, DLC/mod checks, and safe restoration on load.
-- Added tooltip support: if an element has a `tooltip` field, an info icon will appear next to its label.

local M = {}

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
        name    = "facc_ghost_on_death",
        caption = {"facc.ghost-on-death"},
        tooltip = {"tooltip.ghost-on-death"},
        switch  = true
      },
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
        name    = "facc_long_reach",
        caption = {"facc.long-reach"},
        tooltip = {"tooltip.long-reach"},
        slider  = { name="slider_long_reach", min=0, max=100, default=0 }
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
        name    = "facc_auto_instant_research",
        caption = {"facc.auto-instant-research"},
        tooltip = {"tooltip.auto-instant-research"},
        slider  = { name="slider_auto_instant_research", min=1, max=300, default=1 },
        switch  = true
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
        name    = "facc_auto_clean_pollution",
        caption = {"facc.auto-clean-pollution"},
        tooltip = {"tooltip.auto-clean-pollution"},
        slider  = { name="slider_auto_clean_pollution", min=1, max=300, default=1 },
        switch  = true
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
  storage.facc_gui_state = storage.facc_gui_state or {}
  local s = storage.facc_gui_state
  -- if old save's tab no longer exists, reset to "cheats"
  if not (s.tab and TABS[s.tab]) then s.tab = "cheats" end
  s.sliders  = s.sliders  or {}
  s.switches = s.switches or {}
  s.is_open  = s.is_open  or false
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
local function is_feature_enabled(name)
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
local function add_function_block(parent, elem)
  local enabled = is_feature_enabled(elem.name)
  local row     = parent.add{ type="flow", direction="horizontal" }
  row.style.horizontal_spacing = SPACING
  row.style.vertical_align    = "center"

  -- label container (with optional tooltip icon)
  local left = row.add{ type="flow", direction="vertical" }
  left.style.vertical_spacing         = SPACING
  left.style.horizontally_stretchable = true

  if elem.tooltip then
    local label_flow = left.add{ type="flow", direction="horizontal" }
    label_flow.style.horizontal_spacing = 4
    label_flow.style.vertical_align     = "center"
    label_flow.add{ type="label",  caption = elem.caption }
    label_flow.add{ type="sprite", sprite = "info", tooltip = elem.tooltip }
  else
    left.add{ type="label", caption = elem.caption }
  end

  if elem.slider then
    local sf = left.add{ type="flow", direction="horizontal" }
    sf.style.horizontal_spacing = SPACING
    sf.style.vertical_align    = "center"

    local init = storage.facc_gui_state.sliders[elem.slider.name] or elem.slider.default
    local slider = sf.add{
      type            = "slider",
      name            = elem.slider.name,
      minimum_value   = elem.slider.min,
      maximum_value   = elem.slider.max,
      value           = init,
      discrete_slider = true
    }
    slider.style.horizontally_stretchable = true
    slider.enabled = enabled

    if elem.slider.name ~= "slider_platform_distance" then
      local display_value = init
      if elem.slider.name == "slider_set_game_speed" then
        local speeds = {0.25, 0.5, 1, 2, 4, 8, 16, 32, 64}
        display_value = speeds[init] or speeds[3]
      end
      local box = sf.add{
        type      = "textfield",
        name      = elem.slider.name .. "_value",
        text      = tostring(display_value),
        numeric   = true,
        read_only = true,
        style     = "short_number_textfield"
      }
      box.style.width = 40
      box.enabled     = false
    end
  end

  if elem.switch then
    local right = row.add{ type="flow", direction="horizontal" }
    right.style.horizontal_align = "right"
    local state = storage.facc_gui_state.switches[elem.name] and "right" or "left"
    local sw = right.add{
      type                = "switch",
      name                = elem.name,
      switch_state        = state,
      left_label_caption  = {"facc.switch-off"},
      right_label_caption = {"facc.switch-on"}
    }
    sw.enabled = enabled
  else
    if     elem.name ~= "facc_set_platform_distance"
      and elem.name ~= "facc_set_game_speed"
      and elem.name ~= "facc_set_crafting_speed"
      and elem.name ~= "facc_set_mining_speed"
      and elem.name ~= "facc_run_faster"
      and elem.name ~= "facc_increase_robot_speed"
      and elem.name ~= "facc_long_reach"
      and elem.name ~= "facc_ammo_damage_boost"
      and elem.name ~= "facc_turret_damage_boost"
    then
      local right = row.add{ type="flow", direction="horizontal" }
      right.style.horizontal_align = "right"
      local btn = right.add{
        type    = "sprite-button",
        name    = elem.name,
        sprite  = "utility.confirm_slot",
        style   = "item_and_count_select_confirm",
        tooltip = {"facc.confirm-button"}
      }
      -- Disable the “Increase Resources” button when infinite resources is active
      if infinite_resources_enabled and (elem.name == "facc_increase_resources" or elem.name == "facc_regenerate_resources") then
        btn.enabled = false
      else
        btn.enabled = enabled
      end
    end
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

  if player.gui.screen["facc_main_frame"] then
    player.gui.screen["facc_main_frame"].destroy()
  end

  local frame = player.gui.screen.add{ type="frame", name="facc_main_frame", direction="vertical" }
  frame.auto_center = true

  local tf = frame.add{ type="flow", name="title_flow", direction="horizontal" }
  tf.drag_target = frame
  tf.style.horizontal_spacing       = SPACING
  tf.style.horizontally_stretchable = true
  tf.style.vertical_align           = "center"
  tf.add{ type="label", caption={"facc.main-title"}, style="frame_title" }.drag_target = frame
  local spacer = tf.add{ type="empty-widget", style="draggable_space_header" }
  spacer.style.horizontally_stretchable = true
  spacer.style.vertically_stretchable   = true
  spacer.drag_target = frame
  tf.add{ type="sprite-button", name="facc_close_main_gui", sprite="utility/close", style="frame_action_button", tooltip={"facc.close-menu"} }

  local container = frame.add{ type="flow", direction="horizontal" }
  container.style.horizontal_spacing = SPACING

  local menu_frame = container.add{ type="frame", style="inside_shallow_frame", direction="vertical" }
  menu_frame.style.minimal_width         = 200
  menu_frame.style.maximal_width         = 200
  menu_frame.style.vertically_stretchable = true
  menu_frame.style.padding               = SPACING

  local menu_scroll = menu_frame.add{ type="scroll-pane", name="facc_menu_pane", direction="vertical" }
  menu_scroll.horizontal_scroll_policy    = "never"
  menu_scroll.vertical_scroll_policy      = "auto"
  menu_scroll.style.vertically_stretchable = true

  local list = menu_scroll.add{ type="list-box", name="facc_menu_list" }
  list.style.horizontally_stretchable = true
  list.style.minimal_width            = 180
  for _, key in ipairs(TAB_ORDER) do
    list.add_item(TABS[key].label)
  end
  for i, key in ipairs(TAB_ORDER) do
    if key == storage.facc_gui_state.tab then
      list.selected_index = i
      break
    end
  end

  local content_outer = container.add{
    type      = "frame",
    name      = "facc_content_outer",
    style     = "inside_shallow_frame",
    direction = "vertical"
  }
  content_outer.style.horizontally_stretchable = true
  content_outer.style.minimal_width           = 800
  content_outer.style.minimal_height          = 600

  local subheader_frame = content_outer.add{
    type      = "frame",
    name      = "facc_subheader_frame",
    style     = "subheader_frame",
    direction = "horizontal"
  }
  subheader_frame.style.horizontally_stretchable = true
  subheader_frame.add{
    type    = "label",
    name    = "facc_subheader_label",
    caption = TABS[storage.facc_gui_state.tab].label,
    style   = "heading_2_label"
  }

  local content_pane = content_outer.add{ type="scroll-pane", name="facc_content_pane", direction="vertical" }
  content_pane.horizontal_scroll_policy      = "never"
  content_pane.vertical_scroll_policy        = "auto"
  content_pane.style.vertically_stretchable  = true
  content_pane.style.padding                 = SPACING

  for _, key in ipairs(TAB_ORDER) do
    local sec = content_pane.add{ type="flow", name="facc_content_"..key, direction="vertical" }
    sec.visible = (key == storage.facc_gui_state.tab)
    sec.style.vertical_spacing = SPACING
    for _, elem in ipairs(TABS[key].elements) do
      add_function_block(sec, elem)
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
  for _, player in pairs(game.players) do
    if not game.is_multiplayer() or player.admin then
      open_gui(player)
    end
  end
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

return M
