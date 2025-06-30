-- scripts/gui/main_gui.lua
-- Main GUI for the Factorio Admin Command Center (FACC)
-- Implements a tabbed interface with persistent state, DLC/mod checks, and safe restoration on load.

local M = {}

--------------------------------------------------------------------------------
-- Mod detection
--------------------------------------------------------------------------------
local quality_enabled   = script.active_mods["quality"]   ~= nil
local space_age_enabled = script.active_mods["space-age"] ~= nil

--------------------------------------------------------------------------------
-- Persistent state schema
--------------------------------------------------------------------------------
--- Ensure the GUI state table exists and initialize defaults.
function M.ensure_persistent_state()
  storage.facc_gui_state = storage.facc_gui_state or {}
  local s = storage.facc_gui_state
  s.tab      = s.tab      or "essentials"
  s.sliders  = s.sliders  or {}
  s.switches = s.switches or {}
  s.is_open  = s.is_open  or false
end

--------------------------------------------------------------------------------
-- Save all slider values recursively
--------------------------------------------------------------------------------
--- Recursively traverse GUI elements to save slider values in storage.
-- @param element LuaGuiElement
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
--- Determine if a feature should be enabled based on active mods.
-- @param name string – the element name
-- @treturn boolean
local function is_feature_enabled(name)
  if name == "facc_set_platform_distance" then
    return space_age_enabled
  end
  if name == "facc_create_legendary_armor" then
    return quality_enabled and space_age_enabled
  end
  if name == "facc_convert_inventory"
      or name == "facc_upgrade_blueprints"
      or name == "facc_convert_to_legendary" then
    return quality_enabled
  end
  return true
end

--------------------------------------------------------------------------------
-- UI layout constants
--------------------------------------------------------------------------------
local SPACING = 12

--------------------------------------------------------------------------------
-- Helper: add a row of controls with label, slider, and switch/button
--------------------------------------------------------------------------------
-- @param parent LuaGuiElement – the container to add into
-- @param elem table – descriptor with fields: name, caption, slider?, switch?
local function add_function_block(parent, elem)
  local enabled = is_feature_enabled(elem.name)

  local row = parent.add{ type = "flow", direction = "horizontal" }
  row.style.horizontal_spacing = SPACING
  row.style.vertical_align    = "center"

  -- Left side: label and optional slider
  local left = row.add{ type = "flow", direction = "vertical" }
  left.style.vertical_spacing         = SPACING
  left.style.horizontally_stretchable = true
  left.add{ type = "label", caption = elem.caption }

  if elem.slider then
    local sf = left.add{ type = "flow", direction = "horizontal" }
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

    local box = sf.add{
      type      = "textfield",
      name      = elem.slider.name .. "_value",
      text      = tostring(init),
      numeric   = true,
      read_only = true,
      style     = "short_number_textfield"
    }
    box.style.width = 40
    box.enabled = enabled
  end

  -- Right side: switch or confirm button
  local right = row.add{ type = "flow", direction = "horizontal" }
  right.style.horizontal_align = "right"
  if elem.switch then
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
    local btn = right.add{
      type    = "sprite-button",
      name    = elem.name,
      sprite  = "utility.confirm_slot",
      style   = "item_and_count_select_confirm",
      tooltip = {"facc.confirm-button"}
    }
    btn.enabled = enabled
  end
end

--------------------------------------------------------------------------------
-- Tab definitions
--------------------------------------------------------------------------------
local TAB_ORDER = {
  "essentials", "switchers", "automation", "character",
  "blueprint",   "map",        "misc",       "unlocks"
}

local TABS = {
  essentials = {
    label    = {"facc.tab-essentials"},
    elements = {
      { name="facc_toggle_editor", caption={"facc.toggle-editor"} },
      { name="facc_console",       caption={"facc.console"} }
    }
  },
  switchers = {
    label    = {"facc.tab-switchers"},
    elements = {
      { name="facc_indestructible_builds", caption={"facc.indestructible-builds"}, switch=true },
      { name="facc_cheat_mode",            caption={"facc.cheat-mode"},          switch=true },
      { name="facc_always_day",            caption={"facc.always-day"},          switch=true },
      { name="facc_disable_pollution",     caption={"facc.disable-pollution"},   switch=true },
      { name="facc_disable_friendly_fire", caption={"facc.disable-friendly-fire"},switch=true },
      { name="facc_peaceful_mode",         caption={"facc.peaceful-mode"},       switch=true },
      { name="facc_enemy_expansion",       caption={"facc.enemy-expansion"},     switch=true },
      { name="facc_toggle_minable",        caption={"facc.toggle-minable"},      switch=true }
    }
  },
  automation = {
    label    = {"facc.tab-automation"},
    elements = {
      {
        name   = "facc_auto_clean_pollution",
        caption= {"facc.auto-clean-pollution"},
        slider ={ name="slider_auto_clean_pollution", min=1, max=300, default=1 },
        switch = true
      },
      {
        name   = "facc_auto_instant_research",
        caption= {"facc.auto-instant-research"},
        slider ={ name="slider_auto_instant_research", min=1, max=300, default=1 },
        switch = true
      }
    }
  },
  character = {
    label    = {"facc.tab-character"},
    elements = {
      { name="facc_delete_ownerless", caption={"facc.delete-ownerless"} }
    }
  },
  blueprint = {
    label    = {"facc.tab-blueprint"},
    elements = {
      { name="facc_build_all_ghosts", caption={"facc.build-all-ghosts"} }
    }
  },
  map = {
    label    = {"facc.tab-map"},
    elements = {
      { name="facc_remove_cliffs",    caption={"facc.remove-cliffs"},   slider={ name="slider_remove_cliffs", min=1, max=150, default=50 } },
      { name="facc_remove_nests",     caption={"facc.remove-nests"},    slider={ name="slider_remove_nests",  min=1, max=150, default=50 } },
      { name="facc_reveal_map",       caption={"facc.reveal-map"},      slider={ name="slider_reveal_map",    min=1, max=150, default=150 } },
      { name="facc_hide_map",         caption={"facc.hide-map"} },
      { name="facc_remove_decon",     caption={"facc.remove-decon"} },
      { name="facc_remove_pollution", caption={"facc.remove-pollution"} }
    }
  },
  misc = {
    label    = {"facc.tab-misc"},
    elements = {
      { name="facc_repair_rebuild",     caption={"facc.repair-rebuild"} },
      { name="facc_recharge_energy",    caption={"facc.recharge-energy"} },
      { name="facc_ammo_turrets",       caption={"facc.ammo-turrets"} },
      { name="facc_increase_resources", caption={"facc.increase-resources"} },
      {
        name   = "facc_set_platform_distance",
        caption= {"facc.platform-distance"},
        slider ={ name="slider_platform_distance", min=0.0, max=1.0, default=0.99 }
      }
    }
  },
  unlocks = {
    label    = {"facc.tab-unlocks"},
    elements = {
      { name="facc_unlock_recipes",      caption={"facc.unlock-recipes"} },
      { name="facc_unlock_technologies", caption={"facc.unlock-technologies"} }
    }
  }
}

--------------------------------------------------------------------------------
-- Inject quality & Space Age feature entries (always visible)
--------------------------------------------------------------------------------
-- these will be greyed out if the mods are not active
table.insert(TABS.character.elements, { name="facc_convert_inventory",      caption={"facc.convert-inventory"} })
table.insert(TABS.character.elements, { name="facc_create_legendary_armor", caption={"facc.create-legendary-armor"} })
table.insert(TABS.blueprint.elements,  { name="facc_upgrade_blueprints",    caption={"facc.upgrade-blueprints"} })
table.insert(TABS.map.elements,        { name="facc_convert_to_legendary", caption={"facc.convert-to-legendary"}, slider={name="slider_convert_to_legendary", min=1, max=150, default=75} })

--------------------------------------------------------------------------------
-- Build & display the GUI
--------------------------------------------------------------------------------
local function open_gui(player)
  if not (player and player.valid and (not game.is_multiplayer() or player.admin)) then
    player.print({"facc.not-allowed"})
    return
  end
  M.ensure_persistent_state()

  -- destroy existing frame if present
  if player.gui.screen["facc_main_frame"] then
    player.gui.screen["facc_main_frame"].destroy()
  end

  -- main window
  local frame = player.gui.screen.add{ type="frame", name="facc_main_frame", caption="", direction="vertical" }
  frame.auto_center = true

  -- title bar
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

  -- body: sidebar + content
  local container = frame.add{ type="flow", direction="horizontal" }
  container.style.horizontal_spacing = SPACING

  -- sidebar
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

  -- content area
  local content_outer = container.add{ type="frame", style="inside_shallow_frame", direction="vertical" }
  content_outer.style.horizontally_stretchable = true
  content_outer.style.minimal_width           = 600
  content_outer.style.minimal_height          = 400

  local subheader_frame = content_outer.add{ type="frame", style="subheader_frame", direction="horizontal" }
  subheader_frame.style.horizontally_stretchable = true
  subheader_frame.add{ type="label", name="facc_subheader_label", caption=TABS[storage.facc_gui_state.tab].label, style="heading_2_label" }

  local content_pane = content_outer.add{ type="scroll-pane", name="facc_content_pane", direction="vertical" }
  content_pane.horizontal_scroll_policy      = "never"
  content_pane.vertical_scroll_policy        = "auto"
  content_pane.style.vertically_stretchable  = true
  content_pane.style.padding                 = SPACING

  -- build each tab
  M.content_frames = {}
  for _, key in ipairs(TAB_ORDER) do
    local sec = content_pane.add{ type="flow", name="facc_content_"..key, direction="vertical" }
    sec.visible = (key == storage.facc_gui_state.tab)
    sec.style.vertical_spacing = SPACING
    for _, elem in ipairs(TABS[key].elements) do
      add_function_block(sec, elem)
    end
    M.content_frames[key] = sec
  end
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

-- tab switching
script.on_event(defines.events.on_gui_selection_state_changed, function(e)
  local elt = e.element
  if not (elt and elt.valid and elt.name == "facc_menu_list") then return end
  local player = game.get_player(e.player_index)
  M.ensure_persistent_state()

  local idx = elt.selected_index
  if not (idx and TAB_ORDER[idx]) then return end
  storage.facc_gui_state.tab = TAB_ORDER[idx]

  -- rebuild content_frames cache if needed
  if not M.content_frames then open_gui(player) end

  -- show/hide tabs
  for key, frame in pairs(M.content_frames) do
    frame.visible = (key == storage.facc_gui_state.tab)
  end

  -- update subheader
  local frame = player.gui.screen["facc_main_frame"]
  if frame then
    local container = frame.children[2]
    local content_outer = container["facc_content_outer"]
    local subheader = content_outer and content_outer["facc_subheader_frame"]
    local hdr = subheader and subheader["facc_subheader_label"]
    if hdr then hdr.caption = TABS[storage.facc_gui_state.tab].label end
  end
end)

-- close button
script.on_event(defines.events.on_gui_click, function(e)
  if e.element and e.element.valid and e.element.name == "facc_close_main_gui" then
    M.toggle_main_gui(game.get_player(e.player_index))
  end
end)

-- slider change
script.on_event(defines.events.on_gui_value_changed, function(e)
  local elt = e.element
  if elt and elt.valid and elt.type == "slider" then
    storage.facc_gui_state.sliders[elt.name] = elt.slider_value
    local box = elt.parent[elt.name.."_value"]
    if box and box.valid then box.text = tostring(elt.slider_value) end
  end
end)

-- switch toggle
script.on_event(defines.events.on_gui_switch_state_changed, function(e)
  local elt = e.element
  if elt and elt.valid and elt.type == "switch" then
    storage.facc_gui_state.switches[elt.name] = (elt.switch_state == "right")
  end
end)

-- on_load + on_tick for restoring open GUI after load
local restore_on_tick = false
script.on_load(function() restore_on_tick = true end)
script.on_event(defines.events.on_tick, function()
  if restore_on_tick then
    restore_on_tick = false
    M.ensure_persistent_state()
    if storage.facc_gui_state.is_open then
      for _, player in pairs(game.players) do open_gui(player) end
    end
  end
end)

--------------------------------------------------------------------------------
-- Public API: toggle main GUI on/off
--------------------------------------------------------------------------------
--- Toggle the main GUI frame for a player.
-- @param player LuaPlayer
function M.toggle_main_gui(player)
  M.ensure_persistent_state()
  local frame = player.gui.screen["facc_main_frame"]
  if frame then
    -- save sliders before closing
    local container = frame.children[2]
    local content_outer = container and container["facc_content_outer"]
    local pane = content_outer and content_outer["facc_content_pane"]
    if pane then save_all_sliders(pane) end
    frame.destroy()
    storage.facc_gui_state.is_open = false
    M.content_frames = nil
  else
    open_gui(player)
    storage.facc_gui_state.is_open = true
  end
end

return M
