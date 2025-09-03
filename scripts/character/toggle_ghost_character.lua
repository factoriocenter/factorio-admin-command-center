-- scripts/character/toggle_ghost_character.lua

local M = {}

local INV = defines.inventory
local INV_IDS = {
  INV.character_main,
  INV.character_guns,
  INV.character_ammo,
  INV.character_armor,
  INV.character_trash
}

-- ========= Inventory copy =========
local function move_inventory(from_char, to_char, inv_id)
  local src = from_char and from_char.valid and from_char.get_inventory(inv_id)
  local dst = to_char   and to_char.valid   and to_char.get_inventory(inv_id)
  if not (src and dst) then return end
  local n = math.min(#src, #dst)
  for i = 1, n do
    local s = src[i]
    if s and s.valid_for_read and s.count > 0 then
      local d = dst[i]
      local ok_set, set_res = pcall(function() return d.set_stack(s) end)
      if ok_set and set_res then
        s.clear()
      else
        local ok_swap, swapped = pcall(function() return d.swap_stack(s) end)
        if ok_swap and swapped then
        else
          local inserted = dst.insert(s)
          if inserted >= s.count then
            s.clear()
          else
            s.count = s.count - inserted
          end
        end
      end
    end
  end
end

-- ========= Safe field helpers for userdata (LuaLogisticPoint/Section) =========

local function safe_get(u, key)
  local value
  local ok = pcall(function() value = u[key] end)
  if ok then return value end
  return nil
end

local function safe_set(u, key, value)
  if value == nil then return end
  pcall(function() u[key] = value end)
end

-- Some builds expose "trash_unrequested"; others use "trash_not_requested".
local function read_trash_toggle(lp)
  local ok, v = pcall(function() return lp.trash_unrequested end)
  if ok then return v end
  ok, v = pcall(function() return lp.trash_not_requested end)
  if ok then return v end
  return nil
end

local function write_trash_toggle(lp, value)
  if value == nil then return end
  local ok = pcall(function() lp.trash_unrequested = value end)
  if ok then return end
  pcall(function() lp.trash_not_requested = value end)
end

-- ========= Personal logistics snapshot / restore =========

local function snapshot_personal_logistics(player)
  local lp = player.get_requester_point()
  if not (lp and lp.valid) then return nil end

  -- enabled + trash toggle are optional on some versions/mod sets
  local data = {
    enabled      = safe_get(lp, "enabled"),
    trash_toggle = read_trash_toggle(lp),
    sections     = {}
  }

  -- Try reading sections_count; if not present, fall back to probing get_section(i).
  local count = safe_get(lp, "sections_count")
  if type(count) == "number" and count > 0 then
    for i = 1, count do
      local ok, sec = pcall(function() return lp.get_section(i) end)
      if ok and sec then
        local entry = {
          group      = safe_get(sec, "group")      or "",
          name       = safe_get(sec, "name")       or "",
          active     = safe_get(sec, "active"),
          multiplier = safe_get(sec, "multiplier"),
          filters    = {}
        }
        local filters = safe_get(sec, "filters")
        if type(filters) == "table" and #filters > 0 then
          for j = 1, #filters do entry.filters[j] = filters[j] end
        end
        data.sections[#data.sections + 1] = entry
      end
    end
  else
    -- Probe sequentially until get_section(i) fails.
    local i = 1
    while true do
      local ok, sec = pcall(function() return lp.get_section(i) end)
      if not ok or not sec then break end
      local entry = {
        group      = safe_get(sec, "group")      or "",
        name       = safe_get(sec, "name")       or "",
        active     = safe_get(sec, "active"),
        multiplier = safe_get(sec, "multiplier"),
        filters    = {}
      }
      local filters = safe_get(sec, "filters")
      if type(filters) == "table" and #filters > 0 then
        for j = 1, #filters do entry.filters[j] = filters[j] end
      end
      data.sections[#data.sections + 1] = entry
      i = i + 1
    end
  end

  return data
end

local function restore_personal_logistics(player, snap)
  if not snap then return end
  local lp = player.get_requester_point()
  if not (lp and lp.valid) then return end

  if snap.enabled ~= nil then safe_set(lp, "enabled", snap.enabled) end
  write_trash_toggle(lp, snap.trash_toggle)

  -- Remove existing sections (backwards‐compatible).
  local count = safe_get(lp, "sections_count")
  if type(count) == "number" and count > 0 then
    for i = count, 1, -1 do
      pcall(function() lp.remove_section(i) end)
    end
  else
    -- Repeatedly try removing section 1 until it fails.
    while true do
      local ok = pcall(function() lp.remove_section(1) end)
      if not ok then break end
    end
  end

  -- Recreate sections exactly as snapshotted.
  for _, sdata in ipairs(snap.sections or {}) do
    local new_sec
    -- Prefer add_section(group) if supported; otherwise add_section() then set group.
    local ok, sec = pcall(function()
      return lp.add_section((sdata.group and sdata.group ~= "" and sdata.group) or nil)
    end)
    if ok and sec then
      new_sec = sec
    else
      local ok2, sec2 = pcall(function() return lp.add_section() end)
      if ok2 and sec2 then new_sec = sec2 end
    end

    if new_sec then
      safe_set(new_sec, "name",       sdata.name)
      safe_set(new_sec, "group",      sdata.group)
      safe_set(new_sec, "active",     sdata.active)
      safe_set(new_sec, "multiplier", sdata.multiplier)
      if sdata.filters and #sdata.filters > 0 then
        -- Assign the filters array wholesale.
        pcall(function() new_sec.filters = sdata.filters end)
      end
    end
  end
end

-- ========= Character swap =========

local function swap_to(player, new_proto)
  local surf = player.surface
  local old  = player.character

  -- Disallow while driving to avoid edge cases with inventories/cargo.
  if player.driving then
    player.print({"facc.operation-not-while-driving"})
    return
  end

  -- Snapshot personal logistics BEFORE the swap.
  local logistics_snapshot = snapshot_personal_logistics(player)

  local pos = (old and old.valid and old.position)  or player.position
  local dir = (old and old.valid and old.direction) or defines.direction.south

  -- Create the new body.
  local new_char = surf.create_entity{
    name      = new_proto,
    position  = pos,
    direction = dir,
    force     = player.force
  }

  -- Move inventories & copy health first.
  if old and old.valid then
    for _, id in ipairs(INV_IDS) do
      move_inventory(old, new_char, id)
    end
    if old.health and new_char.health then new_char.health = old.health end
  end

  -- Attach the new body to the player.
  player.character = new_char

  -- Restore personal logistics AFTER the swap.
  restore_personal_logistics(player, logistics_snapshot)

  -- Remove the old body.
  if old and old.valid then old.destroy() end
end

-- ========= Public entry point =========

function M.run(player, enable_ghost)
  if not is_allowed(player) then
    player.print({"facc.not-allowed"})
    return
  end

  -- If the player is in god/editor (no character), just create the desired body.
  if not player.character then
    swap_to(player, enable_ghost and "facc-ghost-character" or "character")
    if enable_ghost then
      player.print({"facc.ghost-mode-activated"})
    else
      player.print({"facc.ghost-mode-deactivated"})
    end
    return
  end

  local cur = player.character.name
  if enable_ghost and cur ~= "facc-ghost-character" then
    swap_to(player, "facc-ghost-character")
    player.print({"facc.ghost-mode-activated"})
  elseif (not enable_ghost) and cur ~= "character" then
    swap_to(player, "character")
    player.print({"facc.ghost-mode-deactivated"})
  end
end

return M
