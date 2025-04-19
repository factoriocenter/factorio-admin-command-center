-- scripts/gui/main_gui.lua
-- Main GUI interface for Factorio Admin Command Center

local M = {}

-- Adds a functional block with a label, optional slider, and confirm button
local function add_function_block(parent, elem)
  -- Divider line
  parent.add{type = "line", direction = "horizontal"}

  -- Flow to hold label/slider and button side by side
  local container = parent.add{type = "flow", direction = "horizontal"}
  container.style.vertical_align = "center"
  container.style.horizontally_stretchable = true
  container.style.horizontal_spacing = 6

  -- Left side (label and slider if any)
  local left = container.add{type = "flow", direction = "vertical"}
  left.style.horizontally_stretchable = true
  left.style.vertical_spacing = 4

  left.add{type = "label", caption = elem.caption}

  if elem.slider then
    local slider_row = left.add{type = "flow", direction = "horizontal"}
    slider_row.style.horizontal_spacing = 6
    slider_row.style.vertical_align = "center"

    local slider = slider_row.add{
      type = "slider",
      name = elem.slider.name,
      minimum_value = elem.slider.min,
      maximum_value = elem.slider.max,
      value = elem.slider.default,
      discrete_slider = true
    }
    slider.style.horizontally_stretchable = true

    local value_box = slider_row.add{
      type = "textfield",
      name = elem.slider.name .. "_value",
      text = tostring(elem.slider.default),
      numeric = true,
      read_only = true,
      style = "short_number_textfield"
    }
    value_box.style.width = 40
  end

  -- Right side: confirm button
  local right = container.add{type = "flow", direction = "horizontal"}
  right.style.horizontal_align = "right"
  right.add{
    type = "sprite-button",
    name = elem.name,
    sprite = "utility.confirm_slot",
    style = "item_and_count_select_confirm",
    tooltip = {"facc.confirm-button"}
  }
end

-- Tab definitions
local TABS = {
  editor = {
    label = {"facc.tab-editor"},
    elements = {
      { name = "facc_toggle_editor", caption = {"facc.toggle-editor"}}
    }
  },
  character = {
    label = {"facc.tab-character"},
    elements = {
      {name = "facc_delete_ownerless", caption = {"facc.delete-ownerless"}},
      {name = "facc_convert_inventory", caption = {"facc.convert-inventory"}}
    }
  },
  blueprint = {
    label = {"facc.tab-blueprint"},
    elements = {
      {name = "facc_build_blueprints", caption = {"facc.build-blueprints"}},
      {name = "facc_build_all_ghosts", caption = {"facc.build-all-ghosts"}}
    }
  },
  map = {
    label = {"facc.tab-map"},
    elements = {
      {
        name = "facc_remove_cliffs",
        caption = {"facc.remove-cliffs"},
        slider = {name = "slider_remove_cliffs", min = 1, max = 150, default = 50}
      },
      {
        name = "facc_remove_nests",
        caption = {"facc.remove-nests"},
        slider = {name = "slider_remove_nests", min = 1, max = 150, default = 50}
      },
      {
        name = "facc_reveal_map",
        caption = {"facc.reveal-map"},
        slider = {name = "slider_reveal_map", min = 1, max = 150, default = 150}
      },
      {name = "facc_hide_map", caption = {"facc.hide-map"}},
      {name = "facc_remove_decon", caption = {"facc.remove-decon"}},
      {name = "facc_remove_pollution", caption = {"facc.remove-pollution"}},
      {
        name = "facc_convert_to_legendary",
        caption = {"facc.convert-to-legendary"},
        slider = {name = "slider_convert_to_legendary", min = 1, max = 150, default = 75}
      }
    }
  },
  misc = {
    label = {"facc.tab-misc"},
    elements = {
      {name = "facc_repair_rebuild", caption = {"facc.repair-rebuild"}},
      {name = "facc_recharge_energy", caption = {"facc.recharge-energy"}},
      {name = "facc_ammo_turrets", caption = {"facc.ammo-turrets"}},
      {name = "facc_increase_resources", caption = {"facc.increase-resources"}}
    }
  },
  unlocks = {
    label = {"facc.tab-unlocks"},
    elements = {
      {name = "facc_unlock_recipes", caption = {"facc.unlock-recipes"}},
      {name = "facc_unlock_technologies", caption = {"facc.unlock-technologies"}},
      {name = "facc_unlock_achievements", caption = {"facc.unlock-achievements"}}
    }
  },
  utility = {
    label = {"facc.tab-utility"},
    elements = {
      {name = "facc_console", caption = {"facc.console"}}
    }
  }
}

-- Close GUI
local function close_gui(player)
  local frame = player.gui.screen["facc_main_frame"]
  if frame then frame.destroy() end
end

-- Open GUI
local function open_gui(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local frame = player.gui.screen.add{
    type = "frame",
    name = "facc_main_frame",
    caption = {"facc.main-title"},
    direction = "vertical"
  }
  frame.auto_center = true

  -- Top bar (title + close)
  local header = frame.add{type = "flow", direction = "horizontal"}
  header.style.horizontal_align = "right"
  header.style.horizontally_stretchable = true

  header.add{
    type = "sprite-button",
    name = "facc_close_main_gui",
    sprite = "utility/close_fat",
    style = "tool_button_red",
    tooltip = {"facc.close-menu"}
  }

  -- Tabs
  local tabbed_pane = frame.add{type = "tabbed-pane", name = "facc_tabbed_pane"}

  for key, tab in pairs(TABS) do
    local tab_button = tabbed_pane.add{type = "tab", caption = tab.label}
    local tab_content = tabbed_pane.add{
      type = "flow",
      direction = "vertical",
      name = "facc_tab_" .. key
    }
    tab_content.style.vertically_stretchable = true
    tab_content.style.padding = 8

    tabbed_pane.add_tab(tab_button, tab_content)

    for _, elem in ipairs(tab.elements) do
      add_function_block(tab_content, elem)
    end
  end
end

function M.toggle_main_gui(player)
  if player.gui.screen["facc_main_frame"] then
    close_gui(player)
  else
    open_gui(player)
  end
end

return M
