-- scripts/transportation/set_platform_distance.lua
-- Live synchronization of surface.platform.distance with GUI slider,
-- including immediate update when the slider is moved, and periodic refresh.

local M = {}

--- Set the platform distance threshold on the player's current surface.
-- @param player LuaPlayer
-- @param distance number between 0.0 and 1.0
function M.run(player, distance)
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end

    local surface = player.surface
    if not surface.platform then
        player.print({"facc.platform-distance-no-station"})
        return
    end

    -- Round to two decimal places
    local d = math.floor(distance * 100 + 0.5) / 100

    -- Attempt to set the distance (may fail if trains are currently traveling)
    local ok, err = pcall(function()
        surface.platform.distance = d
    end)
    if not ok then
        player.print({"facc.platform-distance-not-traveling"})
        return
    end

    -- (Optional) feedback could be provided here if desired
end

--- Recursively search for a GUI element by name under a root element.
-- @param element LuaGuiElement
-- @param name string
-- @treturn LuaGuiElement|nil
local function find_child_by_name(element, name)
    if not (element and element.valid and element.children) then
        return nil
    end
    for _, child in pairs(element.children) do
        if child.name == name then
            return child
        end
        local found = find_child_by_name(child, name)
        if found then
            return found
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Periodic update (every 60 ticks = 1 second) to refresh the slider UI
--------------------------------------------------------------------------------
script.on_nth_tick(60, function(event)
    for _, player in pairs(game.players) do
        local frame = player.gui.screen["facc_main_frame"]
        if not (frame and frame.valid) then
            goto continue
        end

        local slider = find_child_by_name(frame, "slider_platform_distance")
        local box    = find_child_by_name(frame, "slider_platform_distance_value")
        if not (slider and slider.valid) then
            goto continue
        end

        local surface = player.surface
        if surface and surface.platform then
            local d = surface.platform.distance or 0
            -- Update slider position
            slider.slider_value = d
            -- If the text box exists, update its display text (rounded to two decimals)
            if box and box.valid then
                local display = math.floor(d * 100 + 0.5) / 100
                box.text = tostring(display)
            end
            -- Enable slider when a platform is present
            slider.enabled = true
        else
            -- Disable slider when no platform detected
            slider.enabled = false
        end

        ::continue::
    end
end)

return M
