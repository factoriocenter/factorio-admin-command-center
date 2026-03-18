-- docs/examples/remote_client_example.lua
-- Example integration from another mod using FACC public remote API.

local FACC_NAMES = { "facc", "factorio_admin_command_center" }

local function resolve_facc_interface()
  for _, name in ipairs(FACC_NAMES) do
    local iface = remote.interfaces[name]
    if iface and iface.run_action then
      return name
    end
  end
  return nil
end

local function facc_call(method, ...)
  local name = resolve_facc_interface()
  if not name then
    return nil, "facc-interface-not-found"
  end

  local ok, result = pcall(remote.call, name, method, ...)
  if not ok then
    return nil, result
  end
  return result, nil
end

local function facc_run(action, player_index, args)
  local result, err = facc_call("run_action", action, player_index, args or {})
  if not result then
    return { ok = false, error = err or "remote-call-failed", action = action }
  end
  return result
end

local function facc_has_action(action)
  local result, err = facc_call("has_action", action)
  if err then return false end
  return result == true
end

local function facc_capabilities()
  local result, err = facc_call("get_capabilities")
  if err then
    return { quality = false, space_age = false, planets = { "nauvis" } }
  end
  return result
end

commands.add_command("facc-demo-status", "Print FACC API status", function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  if not player then return end

  local iface_name = resolve_facc_interface()
  if not iface_name then
    player.print("FACC interface not found")
    return
  end

  local version = facc_call("get_interface_version")
  local mod_version = facc_call("get_mod_version")
  local capabilities = facc_capabilities()

  player.print("FACC interface: " .. iface_name)
  player.print("FACC API version: " .. tostring(version))
  player.print("FACC mod version: " .. tostring(mod_version))
  player.print("Capabilities: quality=" .. tostring(capabilities.quality) .. ", space_age=" .. tostring(capabilities.space_age))
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  if facc_has_action("facc_cheat_mode") then
    facc_call("set_toggle", "facc_cheat_mode", player.index, true)
  end

  if facc_has_action("facc_remove_cliffs") then
    facc_run("facc_remove_cliffs", player.index, { radius = 64 })
  end

  if facc_has_action("facc_run_faster") then
    facc_call("set_value", "facc_run_faster", player.index, 6, nil)
  end
end)

commands.add_command("facc-demo-teleport-nauvis", "Teleport player to Nauvis through FACC", function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  if not player then return end

  if not facc_has_action("facc_teleport_to_planet") then
    player.print("FACC action facc_teleport_to_planet not available")
    return
  end

  local result = facc_run("facc_teleport_to_planet", player.index, { planet_name = "nauvis" })
  if not result.ok then
    player.print("FACC teleport failed: " .. tostring(result.error))
  end
end)

commands.add_command("facc-demo-batch", "Run two FACC actions in batch", function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  if not player then return end

  local calls = {
    { action = "facc_cheat_mode", player_index = player.index, args = { enabled = true } },
    { action = "facc_set_game_speed", player_index = player.index, args = { value = 2 } }
  }

  local result, err = facc_call("run_batch", calls)
  if not result then
    player.print("FACC batch failed: " .. tostring(err))
    return
  end

  if result.results then
    for i, item in ipairs(result.results) do
      if not item.ok then
        player.print("Batch item #" .. i .. " failed: " .. tostring(item.error))
      end
    end
  end
end)

commands.add_command("facc-demo-fast-teleport-save", "Save current position through FACC Fast Teleport API", function(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index)
  if not player then return end

  local result, err = facc_call("save_current_teleport", player.index, "Demo Point")
  if not result then
    player.print("FACC save teleport failed: " .. tostring(err))
    return
  end
  if not result.ok then
    player.print("FACC save teleport failed: " .. tostring(result.error))
    return
  end

  player.print("Saved point id: " .. tostring(result.point and result.point.id))
end)
