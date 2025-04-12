-- control.lua
-- Factorio Admin Command Center
-- This mod provides a central command center for administrative tasks.
-- In SinglePlayer, the main button appears for every player.
-- In Multiplayer, only administrators may see and use the mod.
--
-- Features implemented (all functions can be expanded as needed):
--  1) Lua Console (opened via the "Console" button in the main menu)
--  2) Enter Editor Mode
--  3) Exit Editor Mode
--  4) Delete Ownerless Characters
--  5) Repair & Rebuild
--  6) Ammo to Turrets
--  7) Recharge Energy
--  8) Build Ghost Blueprints
--  9) Increase Resources
-- 10) Convert Constructions to Legendary (150x150)
-- 11) Convert Inventory Items to Legendary [NEW]
-- 12) Build All Ghosts (floors, constructions & landfill)
-- 13) Unlock All Recipes
-- 14) Unlock All Technologies
-- 15) Remove Cliffs (50x50)
-- 16) Remove Marked Structures (Deconstruction marks)
-- 17) Reveal Map (150x150)
-- 18) Hide Map
-- 19) Remove Pollution
-- 20) Remove Nests (50x50)
-- 21) Unlock Achievements
-- 22) "Coming Soon" functionality
--
-- Shortcut: CTRL + . toggles the main menu.
-- The Lua Console is only shown when clicking the "Console" button in the menu.

-- Initialize global variables if not present
if not global then global = {} end
if not global.cmd then global.cmd = "" end  -- To store the last Lua Console command

--------------------------------------------------------------------------------
-- Permission Check Function:
-- If not multiplayer, everyone has access.
-- If multiplayer, only players with admin privileges have access.
--------------------------------------------------------------------------------
local function is_allowed(player)
  if not game.is_multiplayer() then
    return true
  else
    return player.admin
  end
end

--------------------------------------------------------------------------------
-- COMMAND FUNCTIONS
--------------------------------------------------------------------------------

-- 2) Enter Editor Mode
function enter_editor_mode(player)
  player.set_controller{type = defines.controllers.editor}
  player.print({"facc.enter-editor-msg"})
end

-- 3) Exit Editor Mode
function exit_editor_mode(player)
  local new_character = player.surface.create_entity{
    name = "character",
    position = player.position,
    force = player.force
  }
  player.set_controller{
    type = defines.controllers.character,
    character = new_character
  }
  player.print({"facc.exit-editor-msg"})
end

-- 4) Delete Ownerless Characters
function delete_ownerless_characters(player)
  for _, ent in pairs(player.surface.find_entities_filtered{type = "character"}) do
    if ent ~= player.character then
      ent.destroy()
    end
  end
  player.print({"facc.deleted-ownerless-msg"})
end

-- 5) Repair & Rebuild
function repair_rebuild(player)
  local surface = player.surface
  local force = player.force
  for _, ent in pairs(surface.find_entities_filtered{force = force}) do
    if ent.valid and ent.health and ent.health > 0 then
      ent.health = ent.health + 1000000
    end
  end
  for _, ghost in pairs(surface.find_entities_filtered{name = "entity-ghost"}) do
    if ghost.valid then ghost.revive() end
  end
  player.print({"facc.repair-rebuild-msg"})
end

-- 6) Ammo to Turrets
function ammo_turrets(player)
  local surface = player.surface
  local turrets = surface.find_entities_filtered{force = player.force, name = "gun-turret"}
  for _, ent in pairs(turrets) do
    local inv = ent.get_inventory(defines.inventory.turret_ammo)
    if inv and inv.is_empty() then
      inv.insert{name = "uranium-rounds-magazine", count = 10}
    end
  end
  player.print({"facc.ammo-turrets-msg"})
end

-- 7) Recharge Energy
function recharge_energy(player)
  local surface = player.surface
  for _, ent in pairs(surface.find_entities_filtered{force = player.force}) do
    if ent.valid and ent.energy and ent.electric_buffer_size then
      ent.energy = ent.electric_buffer_size
    end
  end
  player.print({"facc.recharge-energy-msg"})
end

-- 8) Build Ghost Blueprints
function build_ghost_blueprints(player)
  local surface = player.surface
  for _, e in pairs(surface.find_entities_filtered{force = player.force, type = "entity-ghost"}) do
    if e.valid then e.revive() end
  end
  for _, t in pairs(surface.find_entities_filtered{type = "tile-ghost"}) do
    if t.valid then
      surface.set_tiles{{name = t.ghost_name, position = t.position}}
    end
  end
  player.print({"facc.build-blueprints-msg"})
end

-- 9) Increase Resources
function increase_resources(player)
  local surface = player.surface
  for _, e in pairs(surface.find_entities_filtered{type = "resource"}) do
    e.amount = 4294967295
  end
  player.print({"facc.increase-resources-msg"})
end

-- 10) Convert Constructions to Legendary (150x150)
function convert_to_legendary(player)
  local surface = player.surface
  local force = player.force
  local px, py = player.position.x, player.position.y
  local area = { {px - 75, py - 75}, {px + 75, py + 75} }
  
  -- 1. Destroy eligible entities to generate ghosts with correct rotation.
  for _, ent in pairs(surface.find_entities_filtered{area = area, force = force}) do
    if ent.valid and ent.minable and ent.prototype.items_to_place_this then
      ent.die()
    end
  end
  
  -- 2. Use an upgrade planner to convert ghosts to legendary quality.
  local inv = game.create_inventory(1)
  inv[1].set_stack{name = "upgrade-planner"}
  local planner = inv[1]
  local mapped = {}
  local function table_size(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
  end

  for _, ghost in pairs(surface.find_entities_filtered{area = area, name = "entity-ghost", force = force}) do
    if ghost.ghost_prototype and ghost.ghost_prototype.items_to_place_this then
      local name = ghost.ghost_name
      if not mapped[name] then
        local i = table_size(mapped) + 1
        local success, err = pcall(function()
          planner.set_mapper(i, "from", {type = "entity", name = name})
          planner.set_mapper(i, "to", {type = "entity", name = name, quality = "legendary"})
        end)
        if success then
          mapped[name] = true
        end
      end
    end
  end

  surface.upgrade_area{
    area = area,
    force = force,
    player = player,
    skip_fog_of_war = true,
    item = planner
  }
  inv.destroy()
  
  -- 3. Rebuild legendary ghosts.
  for _, ghost in pairs(surface.find_entities_filtered{
    area = area,
    name = "entity-ghost",
    force = force
  }) do
    ghost.revive()
  end
  
  player.print({"facc.convert-to-legendary-msg"})
end

-- 11) Convert Inventory Items to Legendary [NEW]
function convert_inventory_to_legendary(player)
  -- Expand player inventory slots temporarily.
  local original_bonus = player.character_inventory_slots_bonus or 0
  if player.character then
    player.character_inventory_slots_bonus = original_bonus + 1000
  end

  local function safe_insert_or_store(item)
    if player.can_insert(item) then
      player.insert(item)
      return true
    else
      local chest = player.surface.find_entity("steel-chest", player.position)
      if not chest then
        chest = player.surface.create_entity{
          name = "steel-chest",
          position = {player.position.x + 1, player.position.y},
          force = player.force
        }
      end
      chest.insert(item)
      return false
    end
  end

  local function convert_inventory(inv)
    for i = 1, #inv do
      local stack = inv[i]
      if stack.valid_for_read and stack.quality ~= "legendary" and stack.count > 0 then
        local name = stack.name
        local count = stack.count
        local removed = inv.remove{name = name, count = count}
        if removed > 0 then
          local ok = pcall(function()
            player.insert{name = name, count = removed, quality = "legendary"}
          end)
          if not ok then
            safe_insert_or_store({name = name, count = removed})
          end
        end
      end
    end
  end

  convert_inventory(player.get_main_inventory())
  convert_inventory(player.get_inventory(defines.inventory.character_guns))
  convert_inventory(player.get_inventory(defines.inventory.character_ammo))

  -- Convert armor and its equipment.
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  local armor_stack = armor_inv[1]
  local equipment_buffer = {}

  if armor_stack.valid_for_read and armor_stack.grid then
    for _, eq in pairs(armor_stack.grid.equipment) do
      table.insert(equipment_buffer, {
        name = eq.name,
        size = (eq.shape.width or 1) * (eq.shape.height or 1)
      })
    end
    for _, eq in pairs(equipment_buffer) do
      pcall(function()
        armor_stack.grid.take{name = eq.name, count = 1}
      end)
    end
  end

  if armor_stack.valid_for_read and armor_stack.quality ~= "legendary" then
    local name = armor_stack.name
    armor_inv.remove{name = name, count = 1}
    local ok = pcall(function()
      player.insert{name = name, count = 1, quality = "legendary"}
    end)
    if not ok then
      safe_insert_or_store({name = name, count = 1})
    end
  end

  local new_armor = armor_inv[1]
  if new_armor.valid_for_read and new_armor.grid then
    table.sort(equipment_buffer, function(a, b) return a.size > b.size end)
    for _, eq in pairs(equipment_buffer) do
      local success = pcall(function()
        new_armor.grid.put{name = eq.name, quality = "legendary"}
      end)
      if not success then
        safe_insert_or_store({name = eq.name, count = 1})
      end
    end
  end

  local final_armor = armor_inv[1]
  if final_armor.valid_for_read then
    local armor_name = final_armor.name
    local armor_quality = final_armor.quality
    armor_inv.remove{name = armor_name, count = 1}
    player.insert{name = armor_name, count = 1, quality = armor_quality}
  end

  if player.character then
    player.character_inventory_slots_bonus = original_bonus
  end

  player.print({"facc.convert-inventory-msg"})
end

-- 12) Build All Ghosts (floors, constructions & landfill)
function build_all_ghosts(player)
  local surface = player.surface
  for _, e in pairs(surface.find_entities_filtered{force = player.force, type = "entity-ghost"}) do
    if e.valid then e.revive() end
  end
  for _, t in pairs(surface.find_entities_filtered{type = "tile-ghost"}) do
    if t.valid then
      if t.ghost_name == "landfill" then
        t.revive()
      else
        surface.set_tiles{{name = t.ghost_name, position = t.position}}
      end
    end
  end
  player.print({"facc.build-all-ghosts-msg"})
end

-- 13) Unlock All Recipes
function unlock_all_recipes(player)
  for _, recipe in pairs(player.force.recipes) do
    recipe.enabled = true
  end
  player.print({"facc.unlock-recipes-msg"})
end

-- 14) Unlock All Technologies
function unlock_all_technologies(player)
  player.force.research_all_technologies()
  player.print({"facc.unlock-technologies-msg"})
end

-- 15) Remove Cliffs (50x50)
function remove_cliffs(player, radius)
  local pos = player.position
  for _, cliff in pairs(player.surface.find_entities_filtered{
    area = { {pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius} },
    type = "cliff"
  }) do
    cliff.destroy()
  end
  player.print({"facc.remove-cliffs-msg", radius, radius})
end

-- 16) Remove Marked Structures (Deconstruction marks)
function remove_deconstruction_marks(player)
  for _, entity in pairs(player.surface.find_entities_filtered{to_be_deconstructed = true}) do
    entity.destroy()
  end
  player.print({"facc.remove-decon-msg"})
end

-- 17) Reveal Map (150x150)
function reveal_map(player, radius)
  local pos = player.position
  player.force.chart(player.surface, {
    {pos.x - radius, pos.y - radius},
    {pos.x + radius, pos.y + radius}
  })
  player.print({"facc.reveal-map-msg", radius, radius})
end

-- 18) Hide Map
function hide_map(player)
  local surface = player.surface
  local force = player.force
  for chunk in surface.get_chunks() do
    force.unchart_chunk({x = chunk.x, y = chunk.y}, surface)
  end
  player.print({"facc.hide-map-msg"})
end

-- 19) Remove Pollution
function remove_pollution(player)
  player.surface.clear_pollution()
  player.print({"facc.remove-pollution-msg"})
end

-- 20) Remove Nests (50x50)
function remove_enemy_nests(player, radius)
  local pos = player.position
  local area = { {pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius} }
  for _, entity in pairs(player.surface.find_entities_filtered{area = area, force = "enemy"}) do
    entity.destroy()
  end
  player.print({"facc.remove-nests-msg", radius, radius})
end

-- 21) Unlock Achievements
function unlock_achievements(player)
  local achievements = {
    "getting-on-track", "getting-on-track-like-a-pro", "there-is-no-spoon",
    "smoke-me-a-kipper-i-will-be-back-for-breakfast", "lazy-bastard"
    -- Add more achievement names as desired
  }
  for _, n in pairs(achievements) do
    pcall(function() player.unlock_achievement(n) end)
  end
  player.print({"facc.unlock-achievements-msg"})
end

--------------------------------------------------------------------------------
-- MAIN MENU INTERFACE FUNCTIONS
--------------------------------------------------------------------------------

-- Adds the main button to the top GUI.
function add_main_button(player)
  if is_allowed(player) then
    if not player.gui.top["factorio_admin_command_center_button"] then
      local btn = player.gui.top.add{
        type = "button",
        name = "factorio_admin_command_center_button",
        caption = {"facc.button-caption"}
      }
      btn.style.minimal_width = 40
      btn.style.minimal_height = 40
    end
  end
end

-- Toggles the main menu in the center GUI.
function toggle_main_gui(player)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  local gui_center = player.gui.center
  local frame_name = "factorio_admin_command_center_frame"

  if gui_center[frame_name] then
    gui_center[frame_name].destroy()
  else
    local frame = gui_center.add{
      type = "frame",
      name = frame_name,
      direction = "vertical",
      caption = {"facc.main-title"}
    }
    -- Add a header flow containing the title and a close menu button.
    local header_flow = frame.add{ type = "flow", direction = "horizontal" }
    header_flow.add{
      type = "label",
      caption = {"facc.main-title"}
    }
    header_flow.add{
      type = "button",
      name = "facc_close_menu",
      caption = {"facc.close-menu"}
    }
    -- Add functional buttons in the desired order:
    frame.add{type = "button", name = "facc_console", caption = {"facc.console"}}
    frame.add{type = "button", name = "facc_enter_editor", caption = {"facc.enter-editor"}}
    frame.add{type = "button", name = "facc_exit_editor", caption = {"facc.exit-editor"}}
    frame.add{type = "button", name = "facc_delete_ownerless", caption = {"facc.delete-ownerless"}}
    frame.add{type = "button", name = "facc_repair_rebuild", caption = {"facc.repair-rebuild"}}
    frame.add{type = "button", name = "facc_ammo_turrets", caption = {"facc.ammo-turrets"}}
    frame.add{type = "button", name = "facc_recharge_energy", caption = {"facc.recharge-energy"}}
    frame.add{type = "button", name = "facc_build_blueprints", caption = {"facc.build-blueprints"}}
    frame.add{type = "button", name = "facc_increase_resources", caption = {"facc.increase-resources"}}
    frame.add{type = "button", name = "facc_convert_to_legendary", caption = {"facc.convert-to-legendary"}}
    frame.add{type = "button", name = "facc_convert_inventory", caption = {"facc.convert-inventory"}}
    frame.add{type = "button", name = "facc_build_all_ghosts", caption = {"facc.build-all-ghosts"}}
    frame.add{type = "button", name = "facc_unlock_recipes", caption = {"facc.unlock-recipes"}}
    frame.add{type = "button", name = "facc_unlock_technologies", caption = {"facc.unlock-technologies"}}
    frame.add{type = "button", name = "facc_remove_cliffs", caption = {"facc.remove-cliffs"}}
    frame.add{type = "button", name = "facc_remove_decon", caption = {"facc.remove-decon"}}
    frame.add{type = "button", name = "facc_reveal_map", caption = {"facc.reveal-map"}}
    frame.add{type = "button", name = "facc_hide_map", caption = {"facc.hide-map"}}
    frame.add{type = "button", name = "facc_remove_pollution", caption = {"facc.remove-pollution"}}
    frame.add{type = "button", name = "facc_remove_nests", caption = {"facc.remove-nests"}}
    frame.add{type = "button", name = "facc_unlock_achievements", caption = {"facc.unlock-achievements"}}
    frame.add{type = "button", name = "facc_coming_soonn", caption = {"facc.coming-soon"}}
  end
end

--------------------------------------------------------------------------------
-- LUA CONSOLE SYSTEM (Based on Someone's LUA-Console)
--------------------------------------------------------------------------------

function toggle_console_gui(player)
  if not is_allowed(player) then
    player.print({"some_luaconsole.not-allowed"})
    return
  end

  local screen = player.gui.screen
  if screen.some_luaconsole then
    global.cmd = screen.some_luaconsole.input.text
    screen.some_luaconsole.destroy()
  else
    local frame = screen.add{
      type = "frame",
      name = "some_luaconsole",
      direction = "vertical",
      caption = {"some_luaconsole.title"}
    }
    frame.add{type = "label", caption = {"some_luaconsole.inputlabel"}}
    local input = frame.add{
      type = "text-box",
      name = "input",
      style = "some_luaconsole_input_textbox"
    }
    input.word_wrap = true
    input.style.maximal_height = (player.display_resolution.height / player.display_scale * 0.6)
    input.text = global.cmd or ""
    local horizontal_flow = frame.add{type = "flow", direction = "horizontal"}
    horizontal_flow.add{
      type = "button",
      name = "some_luaconsole_close",
      style = "back_button",
      caption = {"some_luaconsole.close"},
      tooltip = {"some_luaconsole.close_tooltip"}
    }
    horizontal_flow.add{
      type = "button",
      name = "some_luaconsole_exec",
      style = "confirm_button",
      caption = {"some_luaconsole.exec"},
      tooltip = {"some_luaconsole.exec_tooltip"}
    }
    frame.force_auto_center()
  end
end

function exec_console_command(player)
  if not is_allowed(player) then
    player.print({"some_luaconsole.not-allowed"})
    return
  end

  if player.gui.screen.some_luaconsole then
    global.cmd = player.gui.screen.some_luaconsole.input.text
  end

  local cmd = global.cmd or ""
  cmd = cmd:gsub("game%.player([^s])", "game.players[" .. player.index .. "]%1")

  local f, lserr = loadstring(
    "local ipcs,ipcr = pcall(function() " .. cmd .. " end) " ..
    "if not ipcs then game.players[" .. player.index .. "].print(ipcr) end"
  )
  if not f then
    f, lserr = loadstring("game.players[" .. player.index .. "].print(" .. cmd .. ")")
  end

  if f then
    local pcs, pcerr = pcall(f)
    if not pcs then
      player.print(pcerr:match("^[^\n]*"))
    end
  else
    player.print(lserr:match("^[^\n]*"))
  end
end

--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------

script.on_event(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]
  add_main_button(player)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.players[event.player_index]
  add_main_button(player)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  add_main_button(player)
end)

script.on_event("facc_toggle_gui", function(event)
  local player = game.players[event.player_index]
  toggle_main_gui(player)
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player = game.players[event.player_index]

  if element.name == "factorio_admin_command_center_button" then
    toggle_main_gui(player)
  elseif element.name == "facc_close_menu" then
    if player.gui.center["factorio_admin_command_center_frame"] then
      player.gui.center["factorio_admin_command_center_frame"].destroy()
    end
  elseif element.name == "facc_console" then
    toggle_console_gui(player)
  elseif element.name == "facc_enter_editor" then
    enter_editor_mode(player)
  elseif element.name == "facc_exit_editor" then
    exit_editor_mode(player)
  elseif element.name == "facc_delete_ownerless" then
    delete_ownerless_characters(player)
  elseif element.name == "facc_repair_rebuild" then
    repair_rebuild(player)
  elseif element.name == "facc_ammo_turrets" then
    ammo_turrets(player)
  elseif element.name == "facc_recharge_energy" then
    recharge_energy(player)
  elseif element.name == "facc_build_blueprints" then
    build_ghost_blueprints(player)
  elseif element.name == "facc_increase_resources" then
    increase_resources(player)
  elseif element.name == "facc_convert_to_legendary" then
    convert_to_legendary(player)
  elseif element.name == "facc_convert_inventory" then
    convert_inventory_to_legendary(player)
  elseif element.name == "facc_build_all_ghosts" then
    build_all_ghosts(player)
  elseif element.name == "facc_unlock_recipes" then
    unlock_all_recipes(player)
  elseif element.name == "facc_unlock_technologies" then
    unlock_all_technologies(player)
  elseif element.name == "facc_remove_cliffs" then
    remove_cliffs(player, 50)
  elseif element.name == "facc_remove_decon" then
    remove_deconstruction_marks(player)
  elseif element.name == "facc_reveal_map" then
    reveal_map(player, 150)
  elseif element.name == "facc_hide_map" then
    hide_map(player)
  elseif element.name == "facc_remove_pollution" then
    remove_pollution(player)
  elseif element.name == "facc_remove_nests" then
    remove_enemy_nests(player, 50)
  elseif element.name == "facc_unlock_achievements" then
    unlock_achievements(player)
  elseif element.name == "facc_coming_soonn" then
    player.print({"facc.coming-soon-msg"})
  elseif element.name == "some_luaconsole_exec" then
    exec_console_command(player)
  elseif element.name == "some_luaconsole_close" then
    toggle_console_gui(player)
  end
end)
