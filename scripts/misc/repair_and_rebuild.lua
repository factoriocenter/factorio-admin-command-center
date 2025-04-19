-- scripts/misc/repair_and_rebuild.lua
-- Repairs all damaged entities and revives all ghosts for the player's force

local M = {}

function M.run(player)
  local surface = player.surface
  local force = player.force

  for _, ent in pairs(surface.find_entities_filtered{force = force}) do
    if ent.valid and ent.health and ent.health > 0 then
      local status, _ = pcall(function()
        if ent.prototype and ent.prototype.max_health then
          ent.health = math.min(ent.health + 1000000, ent.prototype.max_health)
        else
          ent.health = ent.health + 1000000
        end
      end)
    end
  end

  for _, ghost in pairs(surface.find_entities_filtered{name = "entity-ghost"}) do
    if ghost.valid then ghost.revive() end
  end

  player.print({"facc.repair-rebuild-msg"})
end

return M
