-- scripts/unlocks/unlock_achievements.lua
-- Unlocks all known achievements (base + Space Age DLC)

local M = {}

function M.run(player)
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

  for _, name in pairs(achievements) do
    pcall(function()
      player.unlock_achievement(name)
    end)
  end

  player.print({"facc.unlock-achievements-msg"})
end

return M
