-- scripts/gui/teleport_gui.lua
-- Fast teleport manager GUI:
-- - Saved custom points per player.
-- - Teleport from force map tags.
-- - Optional hide/show for tags in the picker.

local M = {}

local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")
local gui_events = require("scripts/events/gui_events")

local FRAME_NAME = "facc_tp_frame"

local function find_descendant(root, name)
  if not (root and root.valid and type(name) == "string" and name ~= "") then
    return nil
  end
  if root.children then
    for _, child in pairs(root.children) do
      if child and child.valid then
        if child.name == name then
          return child
        end
        local nested = find_descendant(child, name)
        if nested then
          return nested
        end
      end
    end
  end
  return nil
end

local function get_elem(frame, name)
  return find_descendant(frame, name)
end

local function ensure_root_data()
  local root = flib_table.get_or_insert(storage, "facc_teleport_data", {})
  if type(root) ~= "table" then
    storage.facc_teleport_data = {}
    root = storage.facc_teleport_data
  end
  return root
end

local function ensure_player_data(player_index)
  local root = ensure_root_data()
  local data = flib_table.get_or_insert(root, player_index, {})

  if type(data.points) ~= "table" then
    data.points = {}
  end
  if type(data.hidden_tags) ~= "table" then
    data.hidden_tags = {}
  end
  if type(data.ui) ~= "table" then
    data.ui = {}
  end

  if type(data.next_id) ~= "number" then
    local max_id = 0
    for _, point in ipairs(data.points) do
      local id = point and point.id
      if type(id) == "number" and id > max_id then
        max_id = id
      end
    end
    data.next_id = max_id + 1
  end

  return data
end

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function round_int(value)
  local n = tonumber(value) or 0
  if n >= 0 then
    return math.floor(n + 0.5)
  end
  return math.ceil(n - 0.5)
end

local function format_saved_caption(point)
  local px = round_int(point and point.position and point.position.x or 0)
  local py = round_int(point and point.position and point.position.y or 0)
  local name = trim(point and point.name or "")
  local surface_name = trim(point and point.surface_name or "")
  if name == "" then
    name = "Point"
  end
  if surface_name ~= "" then
    return string.format("%s (%d,%d) [%s]", name, px, py, surface_name)
  end
  return string.format("%s (%d,%d)", name, px, py)
end

local function format_tag_caption(tag_info)
  local px = round_int(tag_info and tag_info.position and tag_info.position.x or 0)
  local py = round_int(tag_info and tag_info.position and tag_info.position.y or 0)
  local text = trim(tag_info and tag_info.text or "")
  if text == "" then
    text = "Tag"
  end
  local surface_name = trim(tag_info and tag_info.surface_name or "")
  if surface_name ~= "" then
    return string.format("%s (%d,%d) [%s]", text, px, py, surface_name)
  end
  return string.format("%s (%d,%d)", text, px, py)
end

local function find_safe_destination(surface, player, desired)
  if not (player and player.valid) then
    return false
  end

  local target = player
  local search_name = "character"

  if player.vehicle and player.vehicle.valid then
    target = player.vehicle
    search_name = player.vehicle.name or "character"
  elseif player.character and player.character.valid and player.character.name then
    search_name = player.character.name
  end

  if desired and surface and surface.valid then
    local ok, teleported = pcall(function()
      return target.teleport(desired, surface)
    end)
    if ok and teleported then
      return true
    end
  end

  if not (surface and surface.valid) then
    return false
  end

  local search_name = "character"
  if player and player.character and player.character.valid and player.character.name then
    search_name = player.character.name
  end

  local center = desired or { x = 0, y = 0 }
  local pos = surface.find_non_colliding_position(search_name, center, 256, 1)
  if not pos then
    pos = surface.find_non_colliding_position("character", center, 256, 1)
  end
  if not pos then
    pos = center
  end

  local ok, teleported = pcall(function()
    return target.teleport(pos, surface)
  end)
  return ok and teleported == true
end

local function collect_visible_tags(player, data)
  local tags = {}
  if not (player and player.valid and player.force and player.force.valid) then
    return tags
  end

  for _, surface in pairs(game.surfaces) do
    local found = player.force.find_chart_tags(surface)
    for _, tag in pairs(found) do
      if tag and tag.valid then
        local text = trim(tag.text)
        if text == "" then
          text = "Tag #" .. tostring(tag.tag_number)
        end
        if not data.hidden_tags[tag.tag_number] then
          tags[#tags + 1] = {
            tag_number = tag.tag_number,
            text = text,
            position = { x = tag.position.x, y = tag.position.y },
            surface_index = tag.surface and tag.surface.index or surface.index,
            surface_name = tag.surface and tag.surface.name or surface.name
          }
        end
      end
    end
  end

  table.sort(tags, function(a, b)
    if a.text ~= b.text then
      return a.text < b.text
    end
    if a.surface_name ~= b.surface_name then
      return a.surface_name < b.surface_name
    end
    if a.position.x ~= b.position.x then
      return a.position.x < b.position.x
    end
    return a.position.y < b.position.y
  end)

  return tags
end

local function count_hidden_tags(hidden_tags)
  local count = 0
  for _ in pairs(hidden_tags or {}) do
    count = count + 1
  end
  return count
end

local function get_frame(player)
  return player and player.valid and player.gui.screen[FRAME_NAME] or nil
end

local function get_selected_saved_point(frame, data)
  local dropdown = get_elem(frame, "facc_tp_saved_dropdown")
  if not (dropdown and dropdown.valid) then
    return nil, nil
  end
  local index = dropdown.selected_index or 0
  if index < 1 or index > #data.points then
    return nil, nil
  end
  return data.points[index], index
end

local function get_selected_tag(data, frame)
  local dropdown = get_elem(frame, "facc_tp_tag_dropdown")
  if not (dropdown and dropdown.valid) then
    return nil, nil
  end
  local tags = data.ui.visible_tags or {}
  local index = dropdown.selected_index or 0
  if index < 1 or index > #tags then
    return nil, nil
  end
  return tags[index], index
end

local function find_saved_index_by_id(data, point_id)
  if type(point_id) ~= "number" then
    return nil, nil
  end
  for i, point in ipairs(data.points) do
    if point and point.id == point_id then
      return i, point
    end
  end
  return nil, nil
end

local function find_tag_by_number(player, data, tag_number, include_hidden)
  if type(tag_number) ~= "number" then
    return nil
  end
  local tags = collect_visible_tags(player, data)
  for _, tag_info in ipairs(tags) do
    if tag_info.tag_number == tag_number then
      return tag_info
    end
  end
  if include_hidden then
    local was_hidden = data.hidden_tags[tag_number]
    data.hidden_tags[tag_number] = nil
    local all_visible = collect_visible_tags(player, data)
    if was_hidden then
      data.hidden_tags[tag_number] = true
    end
    for _, tag_info in ipairs(all_visible) do
      if tag_info.tag_number == tag_number then
        return tag_info
      end
    end
  end
  return nil
end

local function is_allowed_for_api(player)
  if not (player and player.valid) then
    return false, "player-not-found"
  end
  if not is_allowed(player) then
    return false, "not-allowed"
  end
  return true, nil
end

local function copy_saved_point(point)
  if not point then
    return nil
  end
  return {
    id = point.id,
    name = point.name,
    position = {
      x = point.position and point.position.x or 0,
      y = point.position and point.position.y or 0
    },
    surface_index = point.surface_index,
    surface_name = point.surface_name,
    caption = format_saved_caption(point)
  }
end

local function copy_tag(tag_info)
  if not tag_info then
    return nil
  end
  return {
    tag_number = tag_info.tag_number,
    text = tag_info.text,
    position = {
      x = tag_info.position and tag_info.position.x or 0,
      y = tag_info.position and tag_info.position.y or 0
    },
    surface_index = tag_info.surface_index,
    surface_name = tag_info.surface_name,
    caption = format_tag_caption(tag_info)
  }
end

local function allocate_next_point_id(data)
  local used = {}
  for _, point in ipairs(data.points or {}) do
    local id = point and point.id
    if type(id) == "number" and id > 0 then
      used[id] = true
    end
  end

  local candidate = 1
  while used[candidate] do
    candidate = candidate + 1
  end
  return candidate
end

local function refresh_gui(player)
  local frame = get_frame(player)
  if not frame then
    return
  end

  local data = ensure_player_data(player.index)

  local pos_label = get_elem(frame, "facc_tp_current_position_value")
  if pos_label and pos_label.valid then
    pos_label.caption = string.format("(%d,%d)", round_int(player.position.x), round_int(player.position.y))
  end

  local saved_dropdown = get_elem(frame, "facc_tp_saved_dropdown")
  if saved_dropdown and saved_dropdown.valid then
    saved_dropdown.clear_items()
    local selected_index = 0
    for i, point in ipairs(data.points) do
      saved_dropdown.add_item(format_saved_caption(point))
      if point.id == data.ui.selected_saved_id then
        selected_index = i
      end
    end

    if #data.points == 0 then
      saved_dropdown.selected_index = 0
      data.ui.selected_saved_id = nil
    else
      if selected_index == 0 then
        selected_index = 1
      end
      saved_dropdown.selected_index = selected_index
      data.ui.selected_saved_id = data.points[selected_index].id
    end
  end

  local name_input = get_elem(frame, "facc_tp_name_input")
  if name_input and name_input.valid then
    local selected_point = nil
    if data.ui.selected_saved_id then
      for _, point in ipairs(data.points) do
        if point.id == data.ui.selected_saved_id then
          selected_point = point
          break
        end
      end
    end
    if selected_point then
      name_input.text = selected_point.name or ""
    end
  end

  data.ui.visible_tags = collect_visible_tags(player, data)
  local tag_dropdown = get_elem(frame, "facc_tp_tag_dropdown")
  if tag_dropdown and tag_dropdown.valid then
    tag_dropdown.clear_items()
    local selected_tag_index = 0
    for i, tag_info in ipairs(data.ui.visible_tags) do
      tag_dropdown.add_item(format_tag_caption(tag_info))
      if tag_info.tag_number == data.ui.selected_tag_number then
        selected_tag_index = i
      end
    end

    if #data.ui.visible_tags == 0 then
      tag_dropdown.selected_index = 0
      data.ui.selected_tag_number = nil
    else
      if selected_tag_index == 0 then
        selected_tag_index = 1
      end
      tag_dropdown.selected_index = selected_tag_index
      data.ui.selected_tag_number = data.ui.visible_tags[selected_tag_index].tag_number
    end
  end

  local hidden_label = get_elem(frame, "facc_tp_hidden_count_value")
  if hidden_label and hidden_label.valid then
    hidden_label.caption = { "facc.tp-hidden-count", count_hidden_tags(data.hidden_tags) }
  end
end

local function create_gui(player)
  local _, frame = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = FRAME_NAME,
    caption = { "facc.tp-title" },
    direction = "vertical",
    style_mods = {
      minimal_width = 640,
      maximal_width = 900
    },
    children = {
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = 8,
          vertical_align = "center",
          horizontal_align = "left",
          horizontally_stretchable = true
        },
        children = {
          {
            type = "label",
            caption = { "facc.tp-current-position" },
            style = "heading_2_label"
          },
          {
            type = "label",
            name = "facc_tp_current_position_value",
            caption = "(0,0)"
          }
        }
      },
      {
        type = "line",
        direction = "horizontal"
      },
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = 8,
          vertical_align = "center"
        },
        children = {
          {
            type = "label",
            caption = { "facc.tp-name-label" }
          },
          {
            type = "textfield",
            name = "facc_tp_name_input",
            style_mods = {
              minimal_width = 260,
              maximal_width = 420,
              horizontally_stretchable = true
            }
          },
          {
            type = "button",
            name = "facc_tp_save_current",
            caption = { "facc.tp-save-current" },
            style = "confirm_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          }
        }
      },
      {
        type = "line",
        direction = "horizontal"
      },
      {
        type = "label",
        caption = { "facc.tp-saved-list" },
        style = "heading_2_label"
      },
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = 8,
          vertical_align = "center"
        },
        children = {
          {
            type = "drop-down",
            name = "facc_tp_saved_dropdown",
            items = { "" },
            handler = { [defines.events.on_gui_selection_state_changed] = gui_events.handlers.menu_selection },
            style_mods = {
              minimal_width = 520,
              maximal_width = 720,
              horizontally_stretchable = true
            }
          }
        }
      },
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = 8
        },
        children = {
          {
            type = "button",
            name = "facc_tp_teleport_saved",
            caption = { "facc.tp-teleport-saved" },
            style = "confirm_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          },
          {
            type = "button",
            name = "facc_tp_update_selected",
            caption = { "facc.tp-rename-selected" },
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          },
          {
            type = "button",
            name = "facc_tp_delete_selected",
            caption = { "facc.tp-delete-selected" },
            style = "red_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          }
        }
      },
      {
        type = "line",
        direction = "horizontal"
      },
      {
        type = "label",
        caption = { "facc.tp-tags-list" },
        style = "heading_2_label"
      },
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = 8,
          vertical_align = "center"
        },
        children = {
          {
            type = "drop-down",
            name = "facc_tp_tag_dropdown",
            items = { "" },
            handler = { [defines.events.on_gui_selection_state_changed] = gui_events.handlers.menu_selection },
            style_mods = {
              minimal_width = 520,
              maximal_width = 720,
              horizontally_stretchable = true
            }
          }
        }
      },
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = 8
        },
        children = {
          {
            type = "button",
            name = "facc_tp_teleport_tag",
            caption = { "facc.tp-teleport-tag" },
            style = "confirm_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          },
          {
            type = "button",
            name = "facc_tp_hide_tag",
            caption = { "facc.tp-hide-tag" },
            style = "red_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          },
          {
            type = "button",
            name = "facc_tp_unhide_tags",
            caption = { "facc.tp-unhide-tags" },
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          }
        }
      },
      {
        type = "flow",
        direction = "horizontal",
        style_mods = {
          horizontal_spacing = 8,
          vertical_align = "center"
        },
        children = {
          {
            type = "label",
            name = "facc_tp_hidden_count_value",
            caption = { "facc.tp-hidden-count", 0 }
          },
          {
            type = "empty-widget",
            style = "draggable_space_header",
            style_mods = {
              horizontally_stretchable = true
            }
          },
          {
            type = "button",
            name = "facc_tp_close",
            caption = { "facc.close" },
            style = "back_button",
            handler = { [defines.events.on_gui_click] = gui_events.handlers.click }
          }
        }
      }
    }
  })

  frame.auto_center = true
  refresh_gui(player)
end

function M.toggle_teleport_gui(player)
  if not (player and player.valid) then
    return
  end
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local frame = get_frame(player)
  if frame then
    frame.destroy()
    return
  end

  create_gui(player)
end

function M.list_saved_points(player)
  if not (player and player.valid) then
    return false, "player-not-found", nil
  end
  local data = ensure_player_data(player.index)
  local points = {}
  for _, point in ipairs(data.points) do
    points[#points + 1] = copy_saved_point(point)
  end
  return true, nil, points
end

function M.save_current_point(player, point_name)
  local allowed, err = is_allowed_for_api(player)
  if not allowed then
    return false, err, nil
  end

  local data = ensure_player_data(player.index)
  local point_id = allocate_next_point_id(data)
  local name = trim(point_name or "")
  if name == "" then
    name = "Point " .. tostring(point_id)
  end

  local point = {
    id = point_id,
    name = name,
    position = { x = player.position.x, y = player.position.y },
    surface_index = player.surface and player.surface.index or 1,
    surface_name = player.surface and player.surface.name or "nauvis"
  }
  data.next_id = point_id + 1
  data.points[#data.points + 1] = point
  data.ui.selected_saved_id = point.id

  if get_frame(player) then
    refresh_gui(player)
  end
  return true, nil, copy_saved_point(point)
end

function M.rename_saved_point(player, point_id, new_name)
  local allowed, err = is_allowed_for_api(player)
  if not allowed then
    return false, err, nil
  end
  local data = ensure_player_data(player.index)
  local _, point = find_saved_index_by_id(data, point_id)
  if not point then
    return false, "saved-point-not-found", nil
  end

  local name = trim(new_name or "")
  if name == "" then
    return false, "name-empty", nil
  end

  point.name = name
  data.ui.selected_saved_id = point.id
  if get_frame(player) then
    refresh_gui(player)
  end
  return true, nil, copy_saved_point(point)
end

function M.delete_saved_point(player, point_id)
  local allowed, err = is_allowed_for_api(player)
  if not allowed then
    return false, err
  end
  local data = ensure_player_data(player.index)
  local index, point = find_saved_index_by_id(data, point_id)
  if not point then
    return false, "saved-point-not-found"
  end

  table.remove(data.points, index)
  if data.ui.selected_saved_id == point.id then
    data.ui.selected_saved_id = nil
  end
  if get_frame(player) then
    refresh_gui(player)
  end
  return true, nil
end

function M.teleport_to_saved_point(player, point_id)
  local allowed, err = is_allowed_for_api(player)
  if not allowed then
    return false, err, nil
  end
  local data = ensure_player_data(player.index)
  local _, point = find_saved_index_by_id(data, point_id)
  if not point then
    return false, "saved-point-not-found", nil
  end

  local surface = game.surfaces[point.surface_index] or game.surfaces[point.surface_name]
  if not (surface and surface.valid) then
    return false, "surface-missing", nil
  end

  local ok = find_safe_destination(surface, player, point.position)
  if not ok then
    return false, "teleport-failed", nil
  end

  if get_frame(player) then
    refresh_gui(player)
  end
  return true, nil, copy_saved_point(point)
end

function M.list_visible_tags(player)
  if not (player and player.valid) then
    return false, "player-not-found", nil
  end
  local data = ensure_player_data(player.index)
  local tags = collect_visible_tags(player, data)
  data.ui.visible_tags = tags

  local result = {}
  for _, tag_info in ipairs(tags) do
    result[#result + 1] = copy_tag(tag_info)
  end
  return true, nil, result
end

function M.teleport_to_tag(player, tag_number)
  local allowed, err = is_allowed_for_api(player)
  if not allowed then
    return false, err, nil
  end
  local data = ensure_player_data(player.index)
  local tag_info = find_tag_by_number(player, data, tag_number, true)
  if not tag_info then
    return false, "tag-not-found", nil
  end

  local surface = game.surfaces[tag_info.surface_index] or game.surfaces[tag_info.surface_name]
  if not (surface and surface.valid) then
    return false, "surface-missing", nil
  end

  local ok = find_safe_destination(surface, player, tag_info.position)
  if not ok then
    return false, "teleport-failed", nil
  end

  if get_frame(player) then
    refresh_gui(player)
  end
  return true, nil, copy_tag(tag_info)
end

function M.hide_tag(player, tag_number)
  local allowed, err = is_allowed_for_api(player)
  if not allowed then
    return false, err, nil
  end
  local data = ensure_player_data(player.index)
  local tag_info = find_tag_by_number(player, data, tag_number, false)
  if not tag_info then
    return false, "tag-not-found", nil
  end

  data.hidden_tags[tag_number] = true
  if data.ui.selected_tag_number == tag_number then
    data.ui.selected_tag_number = nil
  end
  if get_frame(player) then
    refresh_gui(player)
  end
  return true, nil, copy_tag(tag_info)
end

function M.unhide_all_tags(player)
  local allowed, err = is_allowed_for_api(player)
  if not allowed then
    return false, err, 0
  end
  local data = ensure_player_data(player.index)
  local hidden_count = count_hidden_tags(data.hidden_tags)
  data.hidden_tags = {}
  data.ui.selected_tag_number = nil
  if get_frame(player) then
    refresh_gui(player)
  end
  return true, nil, hidden_count
end

function M.handle_click(player, element)
  if not (player and player.valid and element and element.valid) then
    return
  end

  local name = element.name
  if name == "facc_tp_open" then
    M.toggle_teleport_gui(player)
    return
  end

  local frame = get_frame(player)
  if not frame then
    return
  end

  if name == "facc_tp_close" then
    frame.destroy()
    return
  end

  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  local data = ensure_player_data(player.index)
  local input = get_elem(frame, "facc_tp_name_input")

  if name == "facc_tp_save_current" then
    local point_id = allocate_next_point_id(data)
    local point_name = trim(input and input.text or "")
    if point_name == "" then
      point_name = "Point " .. tostring(point_id)
    end

    local point = {
      id = point_id,
      name = point_name,
      position = { x = player.position.x, y = player.position.y },
      surface_index = player.surface and player.surface.index or 1,
      surface_name = player.surface and player.surface.name or "nauvis"
    }
    data.next_id = point_id + 1
    data.points[#data.points + 1] = point
    data.ui.selected_saved_id = point.id

    refresh_gui(player)
    player.print({ "facc.tp-saved-msg", point.name, round_int(point.position.x), round_int(point.position.y) })
    return
  end

  if name == "facc_tp_update_selected" then
    local point = get_selected_saved_point(frame, data)
    if not point then
      player.print({ "facc.tp-no-saved-selected" })
      return
    end
    local new_name = trim(input and input.text or "")
    if new_name == "" then
      player.print({ "facc.tp-name-empty" })
      return
    end
    point.name = new_name
    data.ui.selected_saved_id = point.id
    refresh_gui(player)
    player.print({ "facc.tp-renamed-msg", new_name })
    return
  end

  if name == "facc_tp_delete_selected" then
    local point, index = get_selected_saved_point(frame, data)
    if not point then
      player.print({ "facc.tp-no-saved-selected" })
      return
    end
    table.remove(data.points, index)
    data.ui.selected_saved_id = nil
    refresh_gui(player)
    player.print({ "facc.tp-deleted-msg" })
    return
  end

  if name == "facc_tp_teleport_saved" then
    local point = get_selected_saved_point(frame, data)
    if not point then
      player.print({ "facc.tp-no-saved-selected" })
      return
    end
    local surface = game.surfaces[point.surface_index] or game.surfaces[point.surface_name]
    if not (surface and surface.valid) then
      player.print({ "facc.tp-surface-missing" })
      return
    end
    if find_safe_destination(surface, player, point.position) then
      player.print({ "facc.tp-teleported-saved-msg", point.name })
      refresh_gui(player)
    else
      player.print({ "facc.tp-teleport-failed" })
    end
    return
  end

  if name == "facc_tp_teleport_tag" then
    local tag_info = get_selected_tag(data, frame)
    if not tag_info then
      player.print({ "facc.tp-no-tag-selected" })
      return
    end
    local surface = game.surfaces[tag_info.surface_index] or game.surfaces[tag_info.surface_name]
    if not (surface and surface.valid) then
      player.print({ "facc.tp-surface-missing" })
      return
    end
    if find_safe_destination(surface, player, tag_info.position) then
      player.print({ "facc.tp-teleported-tag-msg", tag_info.text })
      refresh_gui(player)
    else
      player.print({ "facc.tp-teleport-failed" })
    end
    return
  end

  if name == "facc_tp_hide_tag" then
    local tag_info = get_selected_tag(data, frame)
    if not tag_info then
      player.print({ "facc.tp-no-tag-selected" })
      return
    end
    data.hidden_tags[tag_info.tag_number] = true
    data.ui.selected_tag_number = nil
    refresh_gui(player)
    player.print({ "facc.tp-tag-hidden-msg", tag_info.text })
    return
  end

  if name == "facc_tp_unhide_tags" then
    local hidden_count = count_hidden_tags(data.hidden_tags)
    data.hidden_tags = {}
    data.ui.selected_tag_number = nil
    refresh_gui(player)
    player.print({ "facc.tp-tags-unhidden-msg", hidden_count })
    return
  end
end

function M.handle_selection_state_changed(player, element)
  if not (player and player.valid and element and element.valid) then
    return
  end

  local frame = get_frame(player)
  if not frame then
    return
  end

  local data = ensure_player_data(player.index)

  if element.name == "facc_tp_saved_dropdown" then
    local point = get_selected_saved_point(frame, data)
    data.ui.selected_saved_id = point and point.id or nil
    local input = get_elem(frame, "facc_tp_name_input")
    if input and input.valid then
      input.text = point and (point.name or "") or ""
    end
    return
  end

  if element.name == "facc_tp_tag_dropdown" then
    local tag_info = get_selected_tag(data, frame)
    data.ui.selected_tag_number = tag_info and tag_info.tag_number or nil
  end
end

function M.on_tick(event)
  if not (event and event.tick) then
    return
  end
  if event.tick % 10 ~= 0 then
    return
  end

  for _, player in pairs(game.players) do
    local frame = get_frame(player)
    if frame and frame.valid then
      local pos_label = get_elem(frame, "facc_tp_current_position_value")
      if pos_label and pos_label.valid then
        pos_label.caption = string.format("(%d,%d)", round_int(player.position.x), round_int(player.position.y))
      end
    end
  end
end

gui_events.set_teleport_gui_api(M)

return M
