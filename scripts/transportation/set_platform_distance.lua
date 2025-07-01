-- scripts/misc/set_platform_distance.lua
-- Sets the surface.platform.distance threshold (0.0–1.0).
-- Only callable when the Space Age DLC/mod is present.

local M = {}

--- Apply the chosen platform.distance on the player's current surface.
-- @param player LuaPlayer
-- @param distance number between 0.0 and 1.0
function M.run(player, distance)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end

    local surface = player.surface

    -- If there is no station object on this surface, warn and abort.
    if not surface.platform then
        player.print({"facc.platform-distance-no-station"})
        return
    end

    -- Try setting the distance; station must be traveling or this will error.
    local ok, err = pcall(function()
        surface.platform.distance = distance
    end)
    if not ok then
        player.print({"facc.platform-distance-not-traveling"})
        return
    end

    -- Build the percentage string in code:
    local pct = math.floor(distance * 100)
    local pct_str = tostring(pct) .. "%"   -- e.g. "75%"

    -- Localization key only contains the static text;
    -- we concatenate it with our pct_str and a final period.
    player.print({
        "", 
        {"facc.platform-distance-set"},  -- e.g. "Platform distance set to"
        " " .. pct_str .. "."            -- e.g. " 75%."
    })
end

return M
