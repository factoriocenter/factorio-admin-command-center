-- prototypes/achievements_overrides.lua
-- Override certain achievements only when the corresponding setting is enabled.
-- =============================================================================

local minute = 60
local hour   = 60 * minute

-- Check if overrides are enabled via startup setting
if not (settings.startup["facc-enable-achievement-overrides"] and settings.startup["facc-enable-achievement-overrides"].value) then
  return
end

--- Helper: merge override properties into an achievement prototype.
-- @param id         string – the achievement’s internal name
-- @param type_name  string – the prototype type (e.g. "build-entity-achievement")
-- @param props      table  – key/value pairs to write into the prototype
local function override(id, type_name, props)
  local ach = data.raw[type_name] and data.raw[type_name][id]
  if ach then
    for key, value in pairs(props) do
      ach[key] = value
    end
  end
end

-- 1) You are doing it right
override("you-are-doing-it-right", "construct-with-robots-achievement", {
  more_than_manually = false,
  amount              = 1,
})

-- 2) Getting on track like a pro
override("getting-on-track-like-a-pro", "build-entity-achievement", {
  within = 2147483647 * minute,
})

-- 3) Keeping your hands clean
--    Point the forbidden-kill filter at a ghost so artillery kills still count.
override("keeping-your-hands-clean", "dont-kill-manually-achievement", {
  type_not_to_kill      = "entity-ghost",
  allowed_without_fight = true,
})

-- 4) Lazy bastard
override("lazy-bastard", "dont-craft-manually-achievement", {
  limited_to_one_game = false,
  amount              = 2147483647,
})

-- 5) Steam all the way
override("steam-all-the-way", "dont-use-entity-in-energy-production-achievement", {
  excluded              = "entity-ghost",
  allowed_without_fight = true,
})

-- 6) Raining bullets
override("raining-bullets", "dont-build-entity-achievement", {
  dont_build            = { "entity-ghost" },
  allowed_without_fight = true,
})

-- 7) Logistic network embargo
override("logistic-network-embargo", "dont-build-entity-achievement", {
  dont_build            = { "entity-ghost" },
  allowed_without_fight = true,
})

-- 8) No time for chitchat
override("no-time-for-chitchat", "complete-objective-achievement", {
  within = 2147483647 * hour,
})

-- 9) There is no spoon
override("there-is-no-spoon", "complete-objective-achievement", {
  within = 2147483647 * hour,
})

-- 10) Rush to space (Space Age)
override("rush-to-space", "complete-objective-achievement", {
  allowed_without_fight = true,
})

-- 11) Work around the clock (Space Age)
override("work-around-the-clock", "complete-objective-achievement", {
  within = 2147483647 * hour,
})

-- 12) Express delivery (Space Age)
override("express-delivery", "complete-objective-achievement", {
  within = 2147483647 * hour,
})
