-- scripts/transportation/set_platform_distance.lua
-- Live synchronization of surface.platform.distance with GUI slider,
-- including immediate update when the slider is moved, and periodic refresh.

local M = {}
local math_util = require("scripts/utils/flib_math")
local flib_table = require("__flib__.table")

--- Set the platform distance threshold on the player's current surface.
-- @param player LuaPlayer
-- @param distance number between 0.0 and 1.0
function M.run(player, distance)
    if not (player and player.valid) then return end
    if not is_allowed(player) then
        player.print({"facc.not-allowed"})
        return
    end

    local surface = player.surface
    if not surface.platform then
        player.print({"facc.platform-distance-no-station"})
        return
    end

    distance = math_util.clamp_number(distance, 0, 1, 0.99)

    -- Round to two decimal places
    local d = math_util.round_to(distance, 0.01)

    -- Attempt to set the distance (may fail if trains are currently traveling)
    local ok = pcall(function()
        surface.platform.distance = d
    end)
    if not ok then
        player.print({"facc.platform-distance-not-traveling"})
        return
    end

    -- (Optional) feedback could be provided here if desired
end

local function find_platform_slider(frame)
    local container = frame and frame.children and frame.children[2]
    local outer = container and container["facc_content_outer"]
    local pane = outer and outer["facc_content_pane"]
    local section = pane and pane["facc_content_transportation"]
    if not (section and section.valid) then
        return nil
    end

    for _, row in pairs(section.children) do
        local left = row and row.children and row.children[1]
        local slider_flow = left and left.children and left.children[2]
        local slider = slider_flow and slider_flow["slider_platform_distance"]
        if slider and slider.valid then
            return slider
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Periodic update (every 60 ticks = 1 second) to refresh the slider UI.
-- Event wiring is centralized in scripts/events/build_events.lua.
--------------------------------------------------------------------------------
function M.on_tick(event)
    if not (event and event.tick) then
        return
    end
    if not (storage and storage.facc_gui_state and storage.facc_gui_state.tab == "transportation") then
        return
    end

    flib_table.for_each(game.players, function(player)
        local frame = player.gui.screen["facc_main_frame"]
        if not (frame and frame.valid) then
            return
        end

        local slider = find_platform_slider(frame)
        if not (slider and slider.valid) then
            return
        end

        local surface = player.surface
        if surface and surface.platform then
            local d = surface.platform.distance or 0
            slider.slider_value = d
            slider.enabled = true
        else
            slider.enabled = false
        end
    end)
end

return M
