-- prototypes/achievements_overrides.lua
-- Override certain achievements only when the corresponding setting is enabled.
-- =============================================================================

local minute = 60
local hour   = 60 * minute
local uint32_max = 4294967295
local max_minutes = uint32_max * minute
local max_hours = uint32_max * hour
local min_amount = 1
local relaxed_science_pack = "automation-science-pack"
local relaxed_technology = "automation"
local REMOVE = {}

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
      if value == REMOVE then
        ach[key] = nil
      else
        ach[key] = value
      end
    end
  end
end

-- -----------------------------------------------------------------------------
-- Limitation and timed achievements
-- -----------------------------------------------------------------------------

-- 1) You are doing it right
override("you-are-doing-it-right", "construct-with-robots-achievement", {
  more_than_manually = false,
  amount              = min_amount,
})

-- 2) Getting on track like a pro
override("getting-on-track-like-a-pro", "build-entity-achievement", {
  within = max_minutes,
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
  amount              = uint32_max,
})

-- 5) Steam all the way
override("steam-all-the-way", "dont-use-entity-in-energy-production-achievement", {
  excluded              = "entity-ghost",
  allowed_without_fight = true,
})

-- 6) Raining bullets
override("raining-bullets", "dont-build-entity-achievement", {
  dont_build            = "entity-ghost",
  allowed_without_fight = true,
})

-- 7) Logistic network embargo
override("logistic-network-embargo", "dont-build-entity-achievement", {
  dont_build            = "entity-ghost",
  research_with         = relaxed_science_pack,
  allowed_without_fight = true,
})

-- 8) No time for chitchat
override("no-time-for-chitchat", "complete-objective-achievement", {
  within = max_hours,
  allowed_without_fight = true,
})

-- 9) There is no spoon
override("there-is-no-spoon", "complete-objective-achievement", {
  within = max_hours,
  allowed_without_fight = true,
})

-- 10) Rush to space (Space Age)
override("rush-to-space", "dont-research-before-researching-achievement", {
  dont_research         = "utility-science-pack",
  research_with         = relaxed_science_pack,
  allowed_without_fight = true,
})

-- 11) Work around the clock (Space Age)
override("work-around-the-clock", "complete-objective-achievement", {
  within = max_hours,
  allowed_without_fight = true,
})

-- 12) Express delivery (Space Age)
override("express-delivery", "complete-objective-achievement", {
  within = max_hours,
  allowed_without_fight = true,
})

-- -----------------------------------------------------------------------------
-- Volume-based achievements (lower thresholds)
-- -----------------------------------------------------------------------------

override("automated-construction", "construct-with-robots-achievement", {
  amount = min_amount,
  limited_to_one_game = false,
})

override("automated-cleanup", "deconstruct-with-robots-achievement", {
  amount = min_amount,
})

override("delivery-service", "deliver-by-robots-achievement", {
  amount = min_amount,
})

override("trans-factorio-express", "train-path-achievement", {
  minimum_distance = min_amount,
})

override("golem", "player-damaged-achievement", {
  minimum_damage = min_amount,
})

override("mass-production-1", "produce-achievement", {
  amount = min_amount,
  limited_to_one_game = false,
})

override("mass-production-2", "produce-achievement", {
  amount = min_amount,
  limited_to_one_game = false,
})

override("mass-production-3", "produce-achievement", {
  amount = min_amount,
  limited_to_one_game = false,
})

override("circuit-veteran-1", "produce-per-hour-achievement", { amount = min_amount })
override("circuit-veteran-2", "produce-per-hour-achievement", { amount = min_amount })
override("circuit-veteran-3", "produce-per-hour-achievement", { amount = min_amount })
override("computer-age-1", "produce-per-hour-achievement", { amount = min_amount })
override("computer-age-2", "produce-per-hour-achievement", { amount = min_amount })
override("computer-age-3", "produce-per-hour-achievement", { amount = min_amount })
override("iron-throne-1", "produce-per-hour-achievement", { amount = min_amount })
override("iron-throne-2", "produce-per-hour-achievement", { amount = min_amount })
override("iron-throne-3", "produce-per-hour-achievement", { amount = min_amount })

override("steamrolled", "kill-achievement", { amount = min_amount })
override("pyromaniac", "kill-achievement", { amount = min_amount })
override("run-forrest-run", "kill-achievement", { amount = min_amount })
override("minions", "combat-robot-count-achievement", { count = min_amount })

override("it-stinks-and-they-dont-like-it", "group-attack-achievement", {
  amount = min_amount,
  allowed_without_fight = true,
})

override("it-stinks-and-they-do-like-it", "group-attack-achievement", {
  amount = min_amount,
  allowed_without_fight = true,
})

override("get-off-my-lawn", "group-attack-achievement", {
  amount = min_amount,
  allowed_without_fight = true,
})

override("shattered-planet-1", "space-connection-distance-traveled-achievement", {
  distance = min_amount,
})

override("shattered-planet-2", "space-connection-distance-traveled-achievement", {
  distance = min_amount,
})

override("shattered-planet-3", "space-connection-distance-traveled-achievement", {
  distance = min_amount,
})

-- -----------------------------------------------------------------------------
-- Progression relaxers
-- -----------------------------------------------------------------------------

override("solaris", "dont-use-entity-in-energy-production-achievement", {
  excluded = "entity-ghost",
  included = "solar-panel",
  minimum_energy_produced = "1kW",
  last_hour_only = true,
  allowed_without_fight = true,
})

override("tech-maniac", "research-achievement", {
  research_all = REMOVE,
  technology = relaxed_technology,
})

override("smoke-me-a-kipper-i-will-be-back-for-breakfast", "complete-objective-achievement", {
  allowed_without_fight = true,
})

override("second-star-to-the-right-and-straight-on-till-morning", "complete-objective-achievement", {
  allowed_without_fight = true,
})

-- -----------------------------------------------------------------------------
-- Quality-related Space Age achievements
-- -----------------------------------------------------------------------------

override("look-at-my-shiny-rare-armor", "equip-armor-achievement", {
  limit_quality = "normal",
})

override("todays-fish-is-trout-a-la-creme", "use-item-achievement", {
  limit_quality = "normal",
})

override("my-modules-are-legendary", "produce-achievement", {
  amount = min_amount,
  limited_to_one_game = false,
})

override("no-room-for-more", "place-equipment-achievement", {
  amount = min_amount,
  limit_quality = "normal",
  limit_equip_quality = "normal",
})
