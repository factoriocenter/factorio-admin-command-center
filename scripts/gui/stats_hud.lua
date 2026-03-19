-- scripts/gui/stats_hud.lua
-- Optional lightweight HUD with reusable runtime sensors.

local M = {}

local flib_format = require("__flib__.format")
local flib_table = require("__flib__.table")

local FRAME_NAME = "facc_stats_hud_frame"

local UPDATE_EVERY_TICKS = 60
local RESEARCH_SAMPLE_COUNT = 3
local BASE_PLAYER_RUNNING_SPEED = 0.15
local TICKS_PER_DAY = 60 * 60 * 60 * 24
local Y_OFFSET_ONE_INFO = 22
local Y_OFFSET_TWO_INFOS = 39
local Y_OFFSET_THREE_INFOS = 60

local function ensure_storage()
  local root = flib_table.get_or_insert(storage, "facc_stats_hud", {})
  root.players = root.players or {}
  root.research_samples = root.research_samples or {}
  root.research_eta = root.research_eta or {}
  return root
end

local function read_mod_setting_value(source, name)
  if not source then
    return nil
  end

  local direct = source[name]
  if direct and direct.value ~= nil then
    return direct.value
  end

  local prefixed = source["factorio-admin-command-center." .. name]
  if prefixed and prefixed.value ~= nil then
    return prefixed.value
  end

  for key, setting in pairs(source) do
    if type(key) == "string" and key:sub(-#name) == name then
      if setting and setting.value ~= nil then
        return setting.value
      end
    end
  end

  return nil
end

local function read_setting(player, name, fallback)
  if player and player.valid and player.mod_settings then
    local value = read_mod_setting_value(player.mod_settings, name)
    if value ~= nil then
      return value
    end
  end

  if player and player.valid and settings and settings.get_player_settings then
    local player_settings = settings.get_player_settings(player.index)
    local value = read_mod_setting_value(player_settings, name)
    if value ~= nil then
      return value
    end
  end

  return fallback
end

local function round_1_decimal(value)
  local number = tonumber(value) or 0
  if number >= 0 then
    return math.floor(number * 10 + 0.5) / 10
  end
  return math.ceil(number * 10 - 0.5) / 10
end

local function round_int(value)
  local number = tonumber(value) or 0
  if number >= 0 then
    return math.floor(number + 0.5)
  end
  return math.ceil(number - 0.5)
end

local function read_player_settings(player)
  local cfg = {
    enabled = read_setting(player, "facc-stats-hud-enabled", false) == true,
    show_research_eta = read_setting(player, "facc-stats-hud-show-research-eta", false) == true,
    show_coordinates = read_setting(player, "facc-stats-hud-show-coordinates", false) == true,
    show_distance = read_setting(player, "facc-stats-hud-show-distance-from-point", false) == true,
    show_evolution = read_setting(player, "facc-stats-hud-show-evolution", false) == true,
    show_pollution = read_setting(player, "facc-stats-hud-show-pollution", false) == true,
    show_playtime = read_setting(player, "facc-stats-hud-show-playtime", false) == true,
    show_playtime_days = read_setting(player, "facc-stats-hud-show-playtime-days", false) == true,
    show_daytime = read_setting(player, "facc-stats-hud-show-daytime", false) == true,
    show_movement_speed = read_setting(player, "facc-stats-hud-show-movement-speed", false) == true,
    show_player_max_speed = read_setting(player, "facc-stats-hud-show-player-max-speed", false) == true,
    show_vehicle_max_speed = read_setting(player, "facc-stats-hud-show-vehicle-max-speed", false) == true,
    show_jetpack_fuel = read_setting(player, "facc-stats-hud-show-jetpack-fuel", false) == true,
    show_handcraft_timer = read_setting(player, "facc-stats-hud-show-handcraft-timer", false) == true,
    offset_preset_one_info = read_setting(player, "facc-stats-hud-offset-preset-one-info", false) == true,
    offset_preset_two_infos = read_setting(player, "facc-stats-hud-offset-preset-two-infos", false) == true,
    offset_preset_three_infos = read_setting(player, "facc-stats-hud-offset-preset-three-infos", false) == true,
  }

  local any_sensor_enabled = cfg.show_research_eta
    or cfg.show_coordinates
    or cfg.show_distance
    or cfg.show_evolution
    or cfg.show_pollution
    or cfg.show_playtime
    or cfg.show_daytime
    or cfg.show_movement_speed
    or cfg.show_handcraft_timer

  -- Safety net: if sensor toggles are ON but the master toggle is OFF,
  -- keep HUD visible to avoid "it is enabled but not showing" confusion.
  if not cfg.enabled and any_sensor_enabled then
    cfg.enabled = true
  end

  return cfg
end

local function get_y_offset_from_preset(cfg)
  if cfg.offset_preset_three_infos then
    return Y_OFFSET_THREE_INFOS
  end
  if cfg.offset_preset_two_infos then
    return Y_OFFSET_TWO_INFOS
  end
  return Y_OFFSET_ONE_INFO
end

local function destroy_frame(player)
  local frame = player.gui.screen[FRAME_NAME]
  if frame and frame.valid then
    frame.destroy()
  end
end

local function get_frame_style_name(cfg)
  return "facc_stats_hud_frame_no_ups"
end

local function get_or_build_frame(player, cfg)
  local direction = "vertical"
  local style_name = get_frame_style_name(cfg)
  local frame = player.gui.screen[FRAME_NAME]
  if frame and frame.valid then
    local tags = frame.tags or {}
    if tags.layout_style == style_name and tags.layout_direction == direction then
      return frame
    end
    frame.destroy()
  end

  frame = player.gui.screen.add({
    type = "frame",
    name = FRAME_NAME,
    style = style_name,
    direction = direction,
    ignored_by_interaction = true,
  })
  frame.location = { x = 0, y = 0 }
  frame.tags = { layout_style = style_name, layout_direction = direction }
  return frame
end

local function update_research_eta(root)
  for _, force in pairs(game.forces) do
    local research = force.current_research
    if research and research.valid then
      local samples = root.research_samples[force.index]
      if not samples then
        samples = {}
        root.research_samples[force.index] = samples
      end

      samples[#samples + 1] = { tech = research.name, progress = force.research_progress }
      if #samples > RESEARCH_SAMPLE_COUNT then
        table.remove(samples, 1)
      end

      local estimated_ticks = 0
      local sample_count = 0
      if #samples > 1 then
        for i = 2, #samples do
          local previous_sample = samples[i - 1]
          local current_sample = samples[i]
          if previous_sample.tech == current_sample.tech then
            local speed_per_tick = (current_sample.progress - previous_sample.progress) / UPDATE_EVERY_TICKS
            if speed_per_tick > 0 then
              estimated_ticks = estimated_ticks + ((1 - current_sample.progress) / speed_per_tick)
              sample_count = sample_count + 1
            end
          end
        end
      end

      if sample_count > 0 then
        root.research_eta[force.index] = flib_format.time(estimated_ticks / sample_count)
      else
        root.research_eta[force.index] = "∞"
      end
    else
      root.research_samples[force.index] = nil
      root.research_eta[force.index] = nil
    end
  end
end

local function build_research_line(player, root, cfg)
  if not cfg.show_research_eta then
    return nil
  end
  local eta = root.research_eta[player.force.index]
  if not eta then
    eta = "-"
  end
  return { "", { "facc.stats-hud-research-eta" }, ": ", eta }
end

local function build_coordinates_distance_line(player, cfg)
  if not cfg.show_coordinates and not cfg.show_distance then
    return nil
  end

  local parts = {}
  local pos = player.position
  if cfg.show_coordinates then
    parts[#parts + 1] = string.format("X=%.1f, Y=%.1f", round_1_decimal(pos.x), round_1_decimal(pos.y))
  end

  if cfg.show_distance then
    -- Distance is intentionally always from world origin (0,0).
    local dx = pos.x
    local dy = pos.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if cfg.show_coordinates then
      parts[#parts + 1] = string.format("D=%.1f", round_1_decimal(distance))
    else
      parts[#parts + 1] = string.format("Distance=%.1f", round_1_decimal(distance))
    end
  end

  return { "", { "facc.stats-hud-coordinates-distance" }, ": ", table.concat(parts, ", ") }
end

local function build_evolution_line(player, cfg)
  if not cfg.show_evolution then
    return nil
  end
  local enemy_force = game.forces.enemy
  if not enemy_force then
    return nil
  end
  local evolution = enemy_force.get_evolution_factor(player.surface) * 100
  return {
    "",
    { "facc.stats-hud-evolution" },
    string.format(": %.2f%%", evolution),
  }
end

local function build_pollution_line(player, cfg)
  if not cfg.show_pollution then
    return nil
  end
  local pollution = 0
  local ok = pcall(function()
    pollution = player.surface.get_pollution(player.position)
  end)
  if not ok then
    pollution = 0
  end
  return {
    "",
    { "facc.stats-hud-pollution" },
    string.format(": %.2f", pollution),
  }
end

local function build_playtime_line(cfg)
  if not cfg.show_playtime then
    return nil
  end
  local ticks_played = game.ticks_played
  local days = math.floor(ticks_played / TICKS_PER_DAY)
  if days == 0 or not cfg.show_playtime_days then
    return { "", { "facc.stats-hud-playtime" }, ": ", flib_format.time(ticks_played) }
  end
  local remainder = ticks_played % TICKS_PER_DAY
  return {
    "",
    { "facc.stats-hud-playtime" },
    ": ",
    { "facc.stats-hud-playtime-days", days, flib_format.time(remainder) },
  }
end

local function build_daytime_line(player, cfg)
  if not cfg.show_daytime then
    return nil
  end

  local daytime = player.surface.daytime + 0.5
  local daytime_minutes = math.floor(daytime * 24 * 60)
  local daytime_hours = math.floor(daytime_minutes / 60) % 24
  daytime_minutes = daytime_minutes - (daytime_minutes % 15)

  local ticks_per_day = player.surface.ticks_per_day
  local days = math.floor(1 + ((game.tick + (ticks_per_day / 2)) / ticks_per_day))

  return {
    "",
    { "facc.stats-hud-time" },
    ": " .. string.format("%d:%02d", daytime_hours, daytime_minutes % 60),
    " | ",
    { "facc.stats-hud-day" },
    " " .. flib_format.number(days),
  }
end

local function compute_vehicle_max_speed(vehicle)
  if not (vehicle and vehicle.valid and vehicle.prototype) then
    return 0
  end

  if vehicle.type == "locomotive" and vehicle.train and vehicle.train.valid then
    local speed = vehicle.train.max_forward_speed or 0
    return speed * 60 * 3.6
  end

  local max_speed = vehicle.prototype.max_speed or 0
  return max_speed * 60 * 3.6
end

local function short_energy(e)
  local value = tonumber(e) or 0
  local suffix = "J"
  if value > 1e12 then
    suffix = "TJ"
    value = value / 1e12
  elseif value > 1e9 then
    suffix = "GJ"
    value = value / 1e9
  elseif value > 1e6 then
    suffix = "MJ"
    value = value / 1e6
  elseif value > 1e3 then
    suffix = "kJ"
    value = value / 1e3
  end

  if value > 100 then
    return string.format("%.0f%s", value, suffix)
  elseif value > 10 then
    return string.format("%.1f%s", value, suffix)
  end
  return string.format("%.2f%s", value, suffix)
end

local function get_jetpack_energy_in_inventory(player)
  if not script.active_mods["jetpack"] then
    return nil
  end

  local ok_is_jetpacking, is_jetpacking = pcall(remote.call, "jetpack", "is_jetpacking", player)
  if not ok_is_jetpacking or not is_jetpacking then
    return nil
  end

  local ok_current_fuel, current_fuel = pcall(remote.call, "jetpack", "get_current_fuel_for_character", player)
  if not ok_current_fuel or not current_fuel then
    return nil
  end

  local ok_fuels, fuels = pcall(remote.call, "jetpack", "get_fuels")
  if not ok_fuels or type(fuels) ~= "table" then
    return nil
  end

  local main_inventory = player.get_inventory(defines.inventory.character_main)
  if not main_inventory then
    return nil
  end

  local energy = 0
  for _, fuel in pairs(fuels) do
    local fuel_name = fuel and fuel.fuel_name
    if type(fuel_name) == "string" then
      local proto = prototypes.item and prototypes.item[fuel_name]
      if proto then
        local count = main_inventory.get_item_count(fuel_name)
        if count > 0 then
          energy = energy + count * (proto.fuel_value or 0)
        end
      end
    end
  end

  energy = energy + (current_fuel.energy or 0)
  return energy
end

local function build_movement_speed_line(player, root, cfg)
  if not cfg.show_movement_speed then
    return nil
  end

  local state = flib_table.get_or_insert(root.players, player.index, {})
  local speed_kmh = nil
  local pos = player.position

  if state.previous_position and state.previous_tick then
    local tick_delta = game.tick - state.previous_tick
    if tick_delta > 0 then
      local dx = pos.x - state.previous_position.x
      local dy = pos.y - state.previous_position.y
      local distance = math.sqrt(dx * dx + dy * dy)
      speed_kmh = (distance / tick_delta) * 60 * 3.6
    end
  end

  state.previous_position = { x = pos.x, y = pos.y }
  state.previous_tick = game.tick

  if speed_kmh == nil then
    speed_kmh = 0
  end

  local current_speed = string.format("%03.0f", speed_kmh)
  if player.vehicle and player.vehicle.valid then
    local text = current_speed .. " km/h"
    if cfg.show_vehicle_max_speed then
      local max_speed = compute_vehicle_max_speed(player.vehicle)
      if max_speed > 0 then
        text = string.format("%s/%03.0f km/h", current_speed, max_speed)
      end
    end
    return { "", { "facc.stats-hud-speed-vehicle" }, ": ", text }
  end

  if player.controller_type == defines.controllers.character and player.character and player.character.valid then
    if cfg.show_jetpack_fuel then
      local jet_energy = get_jetpack_energy_in_inventory(player)
      if jet_energy then
        return {
          "",
          { "facc.stats-hud-speed-jet" },
          ": ",
          current_speed,
          " km/h | ",
          { "facc.stats-hud-jet-fuel" },
          ": ",
          short_energy(jet_energy),
        }
      end
    end

    local text = current_speed .. " km/h"
    if cfg.show_player_max_speed then
      local max_speed = (player.character_running_speed or 0) * 60 * 3.6
      if max_speed > 0 then
        local relative = ((player.character_running_speed or 0) / BASE_PLAYER_RUNNING_SPEED) * 100 - 100
        text = string.format("%s/%03.0f km/h (%+.0f%%)", current_speed, max_speed, relative)
      end
    end
    return { "", { "facc.stats-hud-speed-player" }, ": ", text }
  end

  return { "", { "facc.stats-hud-speed-player" }, ": 000 km/h" }
end

local function build_handcraft_timer_line(player, cfg)
  if not cfg.show_handcraft_timer then
    return nil
  end
  if player.controller_type ~= defines.controllers.character then
    return { "", { "facc.stats-hud-handcraft" }, ": -" }
  end
  if not (player.character and player.character.valid) then
    return { "", { "facc.stats-hud-handcraft" }, ": -" }
  end
  if not (player.force and player.force.valid and player.force.recipes) then
    return { "", { "facc.stats-hud-handcraft" }, ": -" }
  end

  local queue_size = 0
  local ok_queue_size = pcall(function()
    queue_size = player.crafting_queue_size
  end)
  if not ok_queue_size or queue_size == 0 or player.cheat_mode then
    return { "", { "facc.stats-hud-handcraft" }, ": -" }
  end

  local crafting_queue = nil
  local ok_queue = pcall(function()
    crafting_queue = player.crafting_queue
  end)
  if not ok_queue or type(crafting_queue) ~= "table" then
    return { "", { "facc.stats-hud-handcraft" }, ": -" }
  end

  local total_energy = 0
  for _, queue_item in ipairs(crafting_queue) do
    local recipe = player.force.recipes[queue_item.recipe]
    if recipe and recipe.valid then
      local recipe_energy = recipe.energy or 0
      total_energy = total_energy + recipe_energy * (queue_item.count or 0)
      if queue_item.index == 1 then
        total_energy = total_energy - recipe_energy * (player.crafting_queue_progress or 0)
      end
    end
  end

  if total_energy <= 0 then
    return { "", { "facc.stats-hud-handcraft" }, ": -" }
  end

  local speed_multiplier = 1 + (player.force.manual_crafting_speed_modifier or 0)
  if player.character and player.character.valid then
    speed_multiplier = speed_multiplier * (1 + (player.character_crafting_speed_modifier or 0))
  end
  if speed_multiplier <= 0 then
    return { "", { "facc.stats-hud-handcraft" }, ": -" }
  end

  local ticks = total_energy * 60 / speed_multiplier
  return { "", { "facc.stats-hud-handcraft" }, ": ", flib_format.time(ticks) }
end

local function collect_lines(player, root, cfg)
  local lines = {}
  local sensor_builders = {
    function() return build_coordinates_distance_line(player, cfg) end,
    function() return build_daytime_line(player, cfg) end,
    function() return build_playtime_line(cfg) end,
    function() return build_evolution_line(player, cfg) end,
    function() return build_pollution_line(player, cfg) end,
    function() return build_research_line(player, root, cfg) end,
    function() return build_movement_speed_line(player, root, cfg) end,
    function() return build_handcraft_timer_line(player, cfg) end,
  }

  for _, build in ipairs(sensor_builders) do
    local line = build()
    if line then
      lines[#lines + 1] = line
    end
  end

  return lines
end

local function update_player(player, root)
  if not (player and player.valid) then
    return
  end

  local cfg = read_player_settings(player)
  if not cfg.enabled then
    destroy_frame(player)
    root.players[player.index] = nil
    return
  end

  local frame = get_or_build_frame(player, cfg)
  local lines = collect_lines(player, root, cfg)
  if #lines == 0 then
    lines[1] = {
      "",
      { "facc.stats-hud-coordinates-distance" },
      ": ",
      string.format("X=%.1f, Y=%.1f", round_1_decimal(player.position.x), round_1_decimal(player.position.y)),
    }
  end

  local children = frame.children
  local used = 0
  for i, caption in ipairs(lines) do
    used = i
    local label = children[i]
    if label and label.valid then
      label.caption = caption
    else
      frame.add({
        type = "label",
        style = "facc_stats_hud_label",
        caption = caption,
      })
    end
  end

  for i = used + 1, #children do
    local label = children[i]
    if label and label.valid then
      label.destroy()
    end
  end

  local opened = player.opened
  local in_train_gui = player.opened_gui_type == defines.gui_type.entity
    and opened and opened.valid
    and opened.type == "locomotive"
  local in_cutscene = player.controller_type == defines.controllers.cutscene
  local y_offset = get_y_offset_from_preset(cfg)

  local location = frame.location or { x = 0, y = 0 }
  location.x = 0
  location.y = (player.controller_type == defines.controllers.remote)
    and math.floor(36 * player.display_scale) + y_offset
    or y_offset
  frame.location = location
  frame.style.width = math.floor(player.display_resolution.width / player.display_scale)
  frame.visible = (used > 0) and (not in_train_gui) and (not in_cutscene)
end

function M.refresh_player(player)
  if not (player and player.valid) then
    return false
  end
  local root = ensure_storage()
  update_research_eta(root)
  update_player(player, root)
  return true
end

function M.get_snapshot(player)
  if not (player and player.valid) then
    return nil
  end
  local root = ensure_storage()
  update_research_eta(root)
  local cfg = read_player_settings(player)
  local lines = collect_lines(player, root, cfg)
  return {
    enabled = cfg.enabled,
    settings = cfg,
    line_count = #lines,
    lines = lines,
    position = {
      x = round_int(player.position.x),
      y = round_int(player.position.y),
      surface = player.surface and player.surface.name or "",
    },
  }
end

script.on_nth_tick(UPDATE_EVERY_TICKS, function()
  local root = ensure_storage()
  update_research_eta(root)
  for _, player in pairs(game.connected_players) do
    update_player(player, root)
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if not event or not event.setting then
    return
  end
  if string.sub(event.setting, 1, 14) ~= "facc-stats-hud" then
    return
  end
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  local root = ensure_storage()
  update_research_eta(root)
  update_player(player, root)
end)

script.on_event(
  { defines.events.on_player_display_resolution_changed, defines.events.on_player_display_scale_changed },
  function(event)
    local player = game.get_player(event.player_index)
    if not player then
      return
    end
    local root = ensure_storage()
    update_player(player, root)
  end
)

return M
