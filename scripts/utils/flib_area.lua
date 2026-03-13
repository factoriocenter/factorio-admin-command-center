-- scripts/utils/flib_area.lua
-- Area helpers backed by FLib position utilities.

local flib_position = require("__flib__.position")

local M = {}

--- Build a square area from a center position and radius.
-- Returns a 2-point area compatible with `find_entities_filtered` and `chart`.
-- @param center MapPosition
-- @param radius number
-- @return BoundingBox
function M.square_from_center(center, radius)
  local r = tonumber(radius) or 0
  local offset = { x = r, y = r }
  local left_top = flib_position.sub(center, offset)
  local right_bottom = flib_position.add(center, offset)
  return { left_top, right_bottom }
end

return M
