-- control.lua
-- Factorio Admin Command Center
-- Integra o sistema de console (baseado no Someone's LUA-Console) e um menu geral cujas funções são acessíveis:
-- Em SinglePlayer: para todos.
-- Em Multiplayer: apenas para o host (definido como player.admin e player.index == 1).

-- Inicializa a variável global de comando
if not global then global = {} end
if not global.cmd then global.cmd = "" end

----------------------------------------
-- Função para verificar permissão --
-- Em SinglePlayer, todos têm acesso.
-- Em Multiplayer, apenas o host (admin e player.index == 1) tem acesso.
----------------------------------------
local function is_allowed(player)
  if not game.is_multiplayer() then
    return true
  end
  return player.admin and player.index == 1
end

----------------------------------------
-- FUNÇÕES DOS COMANDOS --
----------------------------------------

function open_console_mode(player)
  -- O console só deve ser exibido quando clicado dentro do menu
  toggle_console_gui(player)
end

function enter_editor_mode(player)
  player.set_controller{type = defines.controllers.editor}
  player.print({"facc.enter-editor-msg"})
end

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

function delete_ownerless_characters(player)
  for _, ent in pairs(player.surface.find_entities_filtered{type = "character"}) do
    if ent ~= player.character then
      ent.destroy()
    end
  end
  player.print({"facc.deleted-ownerless-msg"})
end

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

function recharge_energy(player)
  local surface = player.surface
  for _, ent in pairs(surface.find_entities_filtered{force = player.force}) do
    if ent.valid and ent.energy and ent.electric_buffer_size then
      ent.energy = ent.electric_buffer_size
    end
  end
  player.print({"facc.recharge-energy-msg"})
end

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

function increase_resources(player)
  local surface = player.surface
  for _, e in pairs(surface.find_entities_filtered{type = "resource"}) do
    e.amount = 4294967295
  end
  player.print({"facc.increase-resources-msg"})
end

function unlock_achievements(player)
  local achievements = {
    "getting-on-track", "getting-on-track-like-a-pro", "smoke-me-a-kipper-i-will-be-back-for-breakfast",
    -- (complete a lista conforme necessário)
    "my-modules-are-legendary", "no-room-for-more"
  }
  for _, n in pairs(achievements) do
    pcall(function() player.unlock_achievement(n) end)
  end
  player.print({"facc.unlock-achievements-msg"})
end

function unlock_all_recipes(player)
  for _, recipe in pairs(player.force.recipes) do
    recipe.enabled = true
  end
  player.print({"facc.unlock-recipes-msg"})
end

function unlock_all_technologies(player)
  player.force.research_all_technologies()
  player.print({"facc.unlock-technologies-msg"})
end

function remove_cliffs(player, radius)
  local pos = player.position
  for _, cliff in pairs(player.surface.find_entities_filtered{
    area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}},
    type = "cliff"
  }) do
    cliff.destroy()
  end
  player.print({"facc.remove-cliffs-msg", radius, radius})
end

function remove_deconstruction_marks(player)
  for _, entity in pairs(player.surface.find_entities_filtered{to_be_deconstructed = true}) do
    entity.destroy()
  end
  player.print({"facc.remove-decon-msg"})
end

function reveal_map(player, radius)
  local pos = player.position
  player.force.chart(player.surface, {
    {pos.x - radius, pos.y - radius},
    {pos.x + radius, pos.y + radius}
  })
  player.print({"facc.reveal-map-msg", radius, radius})
end

function hide_map(player)
  local surface = player.surface
  local force = player.force
  for chunk in surface.get_chunks() do
    force.unchart_chunk({x = chunk.x, y = chunk.y}, surface)
  end
  player.print({"facc.hide-map-msg"})
end

function remove_pollution(player)
  player.surface.clear_pollution()
  player.print({"facc.remove-pollution-msg"})
end

function remove_enemy_nests(player, radius)
  local pos = player.position
  local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
  for _, entity in pairs(player.surface.find_entities_filtered{area = area, force = "enemy"}) do
    entity.destroy()
  end
  player.print({"facc.remove-nests-msg", radius, radius})
end

----------------------------------------
-- FUNÇÕES DA INTERFACE DO MOD --
----------------------------------------

-- Adiciona o botão principal na GUI superior
function add_main_button(player)
  -- Em SinglePlayer, adiciona para todos; em Multiplayer, somente para o host
  if not game.is_multiplayer() or is_allowed(player) then
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

-- Alterna a janela principal na GUI central
function toggle_main_gui(player)
  if not (not game.is_multiplayer() or is_allowed(player)) then
    player.print({"facc.not-allowed"})
    return
  end
  
  if player.gui.center.factorio_admin_command_center_frame then
    player.gui.center.factorio_admin_command_center_frame.destroy()
  else
    local frame = player.gui.center.add{
      type = "frame",
      name = "factorio_admin_command_center_frame",
      direction = "vertical",
      caption = {"facc.main-title"}
    }
    frame.add{type = "button", name = "facc_console", caption = {"facc.console"}}
    frame.add{type = "button", name = "facc_enter_editor", caption = {"facc.enter-editor"}}
    frame.add{type = "button", name = "facc_exit_editor",  caption = {"facc.exit-editor"}}
    frame.add{type = "button", name = "facc_delete_ownerless", caption = {"facc.delete-ownerless"}}
    frame.add{type = "button", name = "facc_repair_rebuild", caption = {"facc.repair-rebuild"}}
    frame.add{type = "button", name = "facc_ammo_turrets", caption = {"facc.ammo-turrets"}}
    frame.add{type = "button", name = "facc_recharge_energy", caption = {"facc.recharge-energy"}}
    frame.add{type = "button", name = "facc_build_blueprints", caption = {"facc.build-blueprints"}}
    frame.add{type = "button", name = "facc_increase_resources", caption = {"facc.increase-resources"}}
    frame.add{type = "button", name = "facc_unlock_achievements", caption = {"facc.unlock-achievements"}}
    frame.add{type = "button", name = "facc_unlock_recipes", caption = {"facc.unlock-recipes"}}
    frame.add{type = "button", name = "facc_unlock_technologies", caption = {"facc.unlock-technologies"}}
    frame.add{type = "button", name = "facc_remove_cliffs", caption = {"facc.remove-cliffs"}}
    frame.add{type = "button", name = "facc_remove_decon", caption = {"facc.remove-decon"}}
    frame.add{type = "button", name = "facc_reveal_map", caption = {"facc.reveal-map"}}
    frame.add{type = "button", name = "facc_hide_map", caption = {"facc.hide-map"}}
    frame.add{type = "button", name = "facc_remove_pollution", caption = {"facc.remove-pollution"}}
    frame.add{type = "button", name = "facc_remove_nests", caption = {"facc.remove-nests"}}
    frame.add{type = "button", name = "facc_coming_soon", caption = {"facc.coming-soon"}}
  end
end

----------------------------------------
-- FUNÇÕES DO CONSOLE (SISTEMA BASEADO NO Someone's LUA-Console) --
----------------------------------------

function toggle_console_gui(player)
  if not (not game.is_multiplayer() or is_allowed(player)) then
    player.print({"some_luaconsole.not-allowed"})
    return
  end
  
  if player.gui.screen.some_luaconsole then
    -- Guarda o comando digitado antes de fechar
    global.cmd = player.gui.screen.some_luaconsole.input.text
    player.gui.screen.some_luaconsole.destroy()
  else
    local frame = player.gui.screen.add{
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
    
    local horizontal_flow = frame.add{
      type = "flow",
      direction = "horizontal"
    }
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
    -- Utilize player.gui.screen para posicionamento centralizado; note que force_auto_center() pode ser usado aqui
    frame.force_auto_center()
  end
end

function exec_console_command(player)
  if not (not game.is_multiplayer() or is_allowed(player)) then
    player.print({"some_luaconsole.not-allowed"})
    return
  end
  local f, lserr, pcs, pcerr, cmd
  if player.gui.screen.some_luaconsole then
    global.cmd = player.gui.screen.some_luaconsole.input.text
  end
  cmd = global.cmd or ""
  cmd = cmd:gsub("game%.player([^s])", "game.players[" .. player.index .. "]%1")
  
  f, lserr = loadstring("local ipcs,ipcr = pcall(function() " .. cmd .. " end) if not ipcs then game.players[" .. player.index .. "].print(ipcr) end")
  if not f then
    f, lserr = loadstring("game.players[" .. player.index .. "].print(" .. cmd .. ")")
  end
  if f then
    pcs, pcerr = pcall(f)
    if not pcs then
      player.print(string.sub(pcerr, 1, pcerr:find("\n")))
    end
  else
    player.print(string.sub(lserr, 1, lserr:find("\n")))
  end
end

----------------------------------------
-- EVENTOS DE INICIALIZAÇÃO E ATALHO/GUI CLICK --
----------------------------------------

-- Adiciona o botão principal ao criar, ao juntar-se ao jogo e ao respawn
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

-- Atalho para abrir/fechar a janela do menu geral (Ctrl + ])
script.on_event("facc_toggle_gui", function(event)
  local player = game.players[event.player_index]
  if not (not game.is_multiplayer() or is_allowed(player)) then
    player.print({"facc.not-allowed"})
    return
  end
  toggle_main_gui(player)
end)

-- Processa cliques na interface geral do mod e no console
script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player = game.players[event.player_index]
  
  if element.name == "factorio_admin_command_center_button" then
    toggle_main_gui(player)
  
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
  
  elseif element.name == "facc_unlock_achievements" then
    unlock_achievements(player)
  
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
  
  elseif element.name == "facc_coming_soon" then
    player.print({"facc.coming-soon-msg"})
  
  -- Processa cliques na interface do console
  elseif element.name == "some_luaconsole_exec" then
    exec_console_command(player)
  elseif element.name == "some_luaconsole_close" then
    toggle_console_gui(player)
  end
end)
