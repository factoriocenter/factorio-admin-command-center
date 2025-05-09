-- scripts/gui/main_gui.lua
-- Main GUI interface for Factorio Admin Command Center with Automation Tab
-- Persists tab, slider, and switch state in `storage`

local M = {}

--------------------------------------------------------------------------------
-- Ensure that our persistent state lives in `storage`
--------------------------------------------------------------------------------
local function ensure_persistent_state()
  storage.facc_gui_state = storage.facc_gui_state or {}
  local s = storage.facc_gui_state
  s.tab      = s.tab      or "editor"  -- last-opened tab key
  s.sliders  = s.sliders  or {}        -- map slider_name -> last value
  s.switches = s.switches or {}        -- map switch_name -> last state
  s.is_open  = s.is_open  or false     -- whether the GUI was open when last saved
end

--------------------------------------------------------------------------------
-- Recursively scan a GUI element and save all slider values into `storage`
--------------------------------------------------------------------------------
local function save_all_sliders(element)
  if element.type == "slider" then
    storage.facc_gui_state.sliders[element.name] = math.floor(element.slider_value)
  end
  if element.children then
    for _, child in ipairs(element.children) do
      save_all_sliders(child)
    end
  end
end

--------------------------------------------------------------------------------
-- Add a function block (label + optional slider + confirm button or switch)
--------------------------------------------------------------------------------
local function add_function_block(parent, elem)
  parent.add{ type="line", direction="horizontal" }
  local flow = parent.add{ type="flow", direction="horizontal" }
  flow.style.vertical_align           = "center"
  flow.style.horizontally_stretchable = true
  flow.style.horizontal_spacing       = 6

  local left = flow.add{ type="flow", direction="vertical" }
  left.style.horizontally_stretchable = true
  left.style.vertical_spacing         = 4
  left.add{ type="label", caption=elem.caption }

  -- Slider if provided
  if elem.slider then
    local row = left.add{ type="flow", direction="horizontal" }
    row.style.horizontal_spacing = 6
    row.style.vertical_align    = "center"

    local saved = storage.facc_gui_state.sliders[elem.slider.name]
    local init  = saved or elem.slider.default

    local slider = row.add{
      type            = "slider",
      name            = elem.slider.name,
      minimum_value   = elem.slider.min,
      maximum_value   = elem.slider.max,
      value           = init,
      discrete_slider = true
    }
    slider.style.horizontally_stretchable = true

    local box = row.add{
      type      = "textfield",
      name      = elem.slider.name .. "_value",
      text      = tostring(init),
      numeric   = true,
      read_only = true,
      style     = "short_number_textfield"
    }
    box.style.width = 40
  end

  -- Right side: confirm button or switch
  local right = flow.add{ type="flow", direction="horizontal" }
  right.style.horizontal_align = "right"

  if elem.switch then
    local state = storage.facc_gui_state.switches[elem.name] and "right" or "left"
    right.add{
      type                = "switch",
      name                = elem.name,
      switch_state        = state,
      left_label_caption  = {"facc.switch-off"},
      right_label_caption = {"facc.switch-on"}
    }
  else
    right.add{
      type    = "sprite-button",
      name    = elem.name,
      sprite  = "utility.confirm_slot",
      style   = "item_and_count_select_confirm",
      tooltip = {"facc.confirm-button"}
    }
  end
end

--------------------------------------------------------------------------------
-- Tab definitions, in fixed order for new indexing
--------------------------------------------------------------------------------
-- Moved "utility" to be immediately after "editor"
local TAB_ORDER = {
  "editor", "utility", "automation",
  "character", "blueprint",
  "map", "misc", "unlocks"
}

local TABS = {
  editor = {
    label    = {"facc.tab-editor"},
    elements = {
      { name="facc_toggle_editor", caption={"facc.toggle-editor"} }
    }
  },
  utility = {
    label    = {"facc.tab-utility"},
    elements = {
      { name="facc_console", caption={"facc.console"} }
    }
  },
  automation = {
    label    = {"facc.tab-automation"},
    elements = {
      {
        name    = "facc_auto_clean_pollution",
        caption = {"facc.auto-clean-pollution"},
        slider  = { name="slider_auto_clean_pollution", min=1, max=300, default=1 },
        switch  = true
      },
      {
        name    = "facc_auto_instant_research",
        caption = {"facc.auto-instant-research"},
        slider  = { name="slider_auto_instant_research", min=1, max=300, default=1 },
        switch  = true
      },
      {
        name    = "facc_indestructible_builds",
        caption = {"facc.indestructible-builds"},
        switch  = true
      },
      { name="facc_cheat_mode",            caption={"facc.cheat-mode"},          switch=true },
      { name="facc_always_day",            caption={"facc.always-day"},          switch=true },
      { name="facc_disable_pollution",     caption={"facc.disable-pollution"},   switch=true },
      { name="facc_disable_friendly_fire", caption={"facc.disable-friendly-fire"},switch=true },
      { name="facc_peaceful_mode",         caption={"facc.peaceful-mode"},       switch=true },
      { name="facc_enemy_expansion",       caption={"facc.enemy-expansion"},     switch=true }
    }
  },
  character = {
    label    = {"facc.tab-character"},
    elements = {
      { name="facc_delete_ownerless",       caption={"facc.delete-ownerless"} },
      { name="facc_convert_inventory",      caption={"facc.convert-inventory"} },
      { name="facc_create_legendary_armor", caption={"facc.create-legendary-armor"} }
    }
  },
  blueprint = {
    label    = {"facc.tab-blueprint"},
    elements = {
      { name="facc_build_all_ghosts",   caption={"facc.build-all-ghosts"} },
      { name="facc_upgrade_blueprints", caption={"facc.upgrade-blueprints"} }
    }
  },
  map = {
    label    = {"facc.tab-map"},
    elements = {
      {
        name   = "facc_remove_cliffs",
        caption= {"facc.remove-cliffs"},
        slider = { name="slider_remove_cliffs", min=1, max=150, default=50 }
      },
      {
        name   = "facc_remove_nests",
        caption= {"facc.remove-nests"},
        slider = { name="slider_remove_nests", min=1, max=150, default=50 }
      },
      {
        name   = "facc_reveal_map",
        caption= {"facc.reveal-map"},
        slider = { name="slider_reveal_map", min=1, max=150, default=150 }
      },
      { name="facc_hide_map",         caption={"facc.hide-map"} },
      { name="facc_remove_decon",     caption={"facc.remove-decon"} },
      { name="facc_remove_pollution", caption={"facc.remove-pollution"} },
      {
        name   = "facc_convert_to_legendary",
        caption= {"facc.convert-to-legendary"},
        slider = { name="slider_convert_to_legendary", min=1, max=150, default=75 }
      }
    }
  },
  misc = {
    label    = {"facc.tab-misc"},
    elements = {
      { name="facc_repair_rebuild",    caption={"facc.repair-rebuild"} },
      { name="facc_recharge_energy",   caption={"facc.recharge-energy"} },
      { name="facc_ammo_turrets",      caption={"facc.ammo-turrets"} },
      { name="facc_increase_resources",caption={"facc.increase-resources"} }
    }
  },
  unlocks = {
    label    = {"facc.tab-unlocks"},
    elements = {
      { name="facc_unlock_recipes",      caption={"facc.unlock-recipes"} },
      { name="facc_unlock_technologies", caption={"facc.unlock-technologies"} },
      { name="facc_unlock_achievements", caption={"facc.unlock-achievements"} }
    }
  }
}

--------------------------------------------------------------------------------
-- Destroy the GUI frame
--------------------------------------------------------------------------------
local function close_gui(player)
  local frame = player.gui.screen["facc_main_frame"]
  if frame then frame.destroy() end
end

--------------------------------------------------------------------------------
-- Construct and show the GUI, restoring state from `storage`
--------------------------------------------------------------------------------
local function open_gui(player)
  if not (player and player.valid and (not game.is_multiplayer() or player.admin)) then
    player.print({"facc.not-allowed"})
    return
  end
  ensure_persistent_state()

  local frame = player.gui.screen.add{
    type      = "frame",
    name      = "facc_main_frame",
    caption   = {"facc.main-title"},
    direction = "vertical"
  }
  frame.auto_center = true

  -- Header close button
  local header = frame.add{ type="flow", direction="horizontal" }
  header.style.horizontal_align         = "right"
  header.style.horizontally_stretchable = true
  header.add{
    type    = "sprite-button",
    name    = "facc_close_main_gui",
    sprite  = "utility/close_fat",
    style   = "tool_button_red",
    tooltip = {"facc.close-menu"}
  }

  -- Tabbed pane
  local pane = frame.add{ type="tabbed-pane", name="facc_tabbed_pane" }
  local tab_indices = {}

  for idx, key in ipairs(TAB_ORDER) do
    local def = TABS[key]
    local btn = pane.add{ type="tab", name="facc_tab_btn_"..key, caption=def.label }
    local content = pane.add{ type="flow", direction="vertical", name="facc_tab_content_"..key }
    content.style.vertically_stretchable = true
    content.style.padding               = 8

    pane.add_tab(btn, content)
    tab_indices[key] = idx

    for _, elem in ipairs(def.elements) do
      add_function_block(content, elem)
    end
  end

  -- Restore last-opened tab
  local saved = storage.facc_gui_state.tab
  if tab_indices[saved] then
    pane.selected_tab_index = tab_indices[saved]
  end
end

--------------------------------------------------------------------------------
-- Toggle the GUI on/off, persisting state in `storage`
--------------------------------------------------------------------------------
function M.toggle_main_gui(player)
  ensure_persistent_state()
  local screen = player.gui.screen
  if screen["facc_main_frame"] then
    local pane = screen["facc_main_frame"]["facc_tabbed_pane"]
    if pane then
      storage.facc_gui_state.tab = TAB_ORDER[pane.selected_tab_index]
      save_all_sliders(pane)
    end
    storage.facc_gui_state.is_open = false
    close_gui(player)
  else
    open_gui(player)
    storage.facc_gui_state.is_open = true
  end
end

-- expose for gui_events
M.ensure_persistent_state = ensure_persistent_state

return M
