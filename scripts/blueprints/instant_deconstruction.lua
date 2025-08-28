-- scripts/blueprints/instant_deconstruction.lua
-- Instantly removes entities when they are marked for deconstruction.
-- Prefers proper mining (to return items); falls back to destroy.

local M = {}

function M.on_marked_for_deconstruction(event)
  local ent = event.entity
  if not (ent and ent.valid) then return end

  -- Ghosts can simply be destroyed
  if ent.type == "entity-ghost" then
    ent.destroy({ raise_destroy = true })
    return
  end

  -- Prefer mining to recover items
  local player = event.player_index and game.get_player(event.player_index) or nil
  local mined_ok = false

  if player then
    mined_ok = pcall(function()
      return ent.mine({ force = player.force, player = player })
    end) and true or false
  end

  if not mined_ok then
    -- Fallback: destroy (may spill items depending on prototype)
    ent.destroy({ raise_destroy = true })
  end
end

return M
