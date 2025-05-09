-- scripts/unlocks/unlock_achievements.lua
-- Unlock All Achievements module for Factorio Admin Command Center (FACC)
-- Only admins (or single-player) may use this feature.
--
-- This script attempts to unlock a predefined list of achievements for the
-- invoking player. Errors during unlock (e.g. achievement already unlocked)
-- are safely pcallʼd and ignored.

local M = {}

--- Runs the unlock process.
-- @param player LuaPlayer object invoking the command.
function M.run(player)
  -- Permission check: allow only in single-player or for admins
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  -- List of achievements to unlock
  local achievements = {
    "getting-on-track",
    "getting-on-track-like-a-pro",
    "steam-all-the-way",
    "mass-production-1",
    "mass-production-2",
    "mass-production-3",
    "you-are-doing-it-right",
    "automated-construction",
    "it-stinks-and-they-dont-like-it",
    "tech-maniac",
    "lazy-bastard",
    "no-time-for-chitchat",
    "there-is-no-spoon",
    "raining-bullets",
    "iron-throne",
    "pyromaniac",
    "run-forrest-run",
    "watch-your-step",
    "solar-powered",
    "logistic-network-embargo",
    "iron-curtain",
    "smoke-me-a-kipper-i-will-be-back-for-breakfast",
    "trans-factorio-express",
    "space-age",
    "asteroid-mining",
    "asteroid-destroyer",
    "asteroid-field-conqueror",
    "asteroid-factory-master",
    "core-extraction",
    "intergalactic-automation",
    "nanobot-overlord",
    "railgun-express",
    "space-age-mass-production",
    "solar-system-dominator",
    "factory-in-space",
    "cosmic-construction",
    "void-tamer",
    "planet-hopper",
    "galactic-tycoon",
    "interstellar-logistics",
    "faster-than-light",
    "quantum-researcher",
    "singularity-reached",
    "satellite-relay-network",
    "galaxy-conqueror"
  }

  -- Attempt to unlock each achievement, ignoring any errors
  for _, name in ipairs(achievements) do
    pcall(function()
      player.unlock_achievement(name)
    end)
  end

  -- Notify player of success
  player.print({ "facc.unlock-achievements-msg" })
end

return M
