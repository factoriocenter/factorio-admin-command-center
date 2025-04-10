-- control.lua
-- Factorio Admin Command Center
-- Regras:
--   - Em SinglePlayer: o botão principal aparece para qualquer jogador.
--   - Em Multiplayer: o botão aparece somente para administradores.
-- O atalho (Ctrl + ]) abre/fecha o menu geral, e o console Lua é exibido somente quando o usuário clica no botão "Console" dentro do menu.

-- Inicializa as variáveis globais se ainda não existirem
if not global then global = {} end
if not global.cmd then global.cmd = "" end

------------------------------------------------
-- Função de Verificação de Permissão
-- Se não for multiplayer, todo mundo tem acesso.
-- Se for multiplayer, apenas admins podem usar.
------------------------------------------------
local function is_allowed(player)
  if not game.is_multiplayer() then
    return true
  else
    return player.admin
  end
end

------------------------------------------------
-- EXEMPLO DE FUNÇÕES DE COMANDOS
-- (Você pode adicionar outras funções conforme necessário)
------------------------------------------------

function remove_enemy_nests(player, radius)
  local pos = player.position
  local area = { {pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius} }
  for _, entity in pairs(player.surface.find_entities_filtered{ area = area, force = "enemy" }) do
    entity.destroy()
  end
  player.print({"facc.remove-nests-msg", radius, radius})
end

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
    force.unchart_chunk({ x = chunk.x, y = chunk.y }, surface)
  end
  player.print({"facc.hide-map-msg"})
end

-- Outras funções, tais como modo editor, reparo/reconstrução, munição, etc.,
-- devem ser implementadas de maneira semelhante conforme seu desejo.

------------------------------------------------
-- INTERFACE DO MOD: BOTÃO PRINCIPAL E MENU GERAL
------------------------------------------------

-- Adiciona o botão principal na GUI superior
function add_main_button(player)
  if is_allowed(player) then
    if not player.gui.top["factorio_admin_command_center_button"] then
      local btn = player.gui.top.add{
        type = "button",
        name = "factorio_admin_command_center_button",
        caption = {"facc.button-caption"}  -- Usa a chave de tradução
      }
      btn.style.minimal_width = 40
      btn.style.minimal_height = 40
    end
  end
end

-- Alterna o menu principal na GUI central
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
    -- Adiciona os botões do menu (adicione mais conforme necessário)
    frame.add{type = "button", name = "facc_console", caption = {"facc.console"}}
    frame.add{type = "button", name = "facc_remove_nests", caption = {"facc.remove-nests"}}
    frame.add{type = "button", name = "facc_remove_cliffs", caption = {"facc.remove-cliffs"}}
    frame.add{type = "button", name = "facc_reveal_map", caption = {"facc.reveal-map"}}
    frame.add{type = "button", name = "facc_hide_map", caption = {"facc.hide-map"}}
    frame.add{type = "button", name = "facc_coming_soon", caption = {"facc.coming-soon"}}
  end
end

------------------------------------------------
-- SISTEMA DE CONSOLE (baseado no Someone's LUA-Console)
-- O console é aberto quando o botão "Console" no menu é clicado.
------------------------------------------------

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
    "local ipcs,ipcr=pcall(function() " .. cmd .. " end) " ..
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

------------------------------------------------
-- EVENTOS DE INICIALIZAÇÃO, ATALHO E CLIQUES
------------------------------------------------

-- Adiciona o botão principal quando o jogador é criado, entra no jogo ou respawna
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

-- Atalho para abrir/fechar o menu principal (Ctrl + ])
script.on_event("facc_toggle_gui", function(event)
  local player = game.players[event.player_index]
  toggle_main_gui(player)
end)

-- Processa os cliques na GUI
script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player = game.players[event.player_index]

  if element.name == "factorio_admin_command_center_button" then
    toggle_main_gui(player)

  -- Botões do menu principal
  elseif element.name == "facc_console" then
    toggle_console_gui(player)
    
  elseif element.name == "facc_remove_nests" then
    remove_enemy_nests(player, 50)

  elseif element.name == "facc_remove_cliffs" then
    remove_cliffs(player, 50)

  elseif element.name == "facc_reveal_map" then
    reveal_map(player, 150)

  elseif element.name == "facc_hide_map" then
    hide_map(player)

  elseif element.name == "facc_coming_soonn" or element.name == "facc_coming-soon" or element.name == "facc_coming_soon" then
    player.print({"facc.coming-soon-msg"})

  -- Botões do console
  elseif element.name == "some_luaconsole_exec" then
    exec_console_command(player)
  elseif element.name == "some_luaconsole_close" then
    toggle_console_gui(player)
  end
end)
