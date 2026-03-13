-- scripts/utils/flib_math.lua
-- Shared math helpers backed by FLib.

local flib_math = require("__flib__.math")

local M = {}

--- Clamp a numeric value between bounds.
-- If the value is not numeric, `fallback` is used (or `min_value` when omitted).
-- @param value any
-- @param min_value number
-- @param max_value number
-- @param fallback number?
-- @return number
function M.clamp_number(value, min_value, max_value, fallback)
  local n = tonumber(value)
  if n == nil then
    n = (fallback ~= nil) and fallback or min_value
  end
  return flib_math.clamp(n, min_value, max_value)
end

--- Round a numeric value to the nearest multiple of `step`.
-- @param value number
-- @param step number?
-- @return number
function M.round_to(value, step)
  return flib_math.round(value, step or 1)
end

--- Floor wrapper to keep all math calls centralized on FLib.
-- @param value number
-- @return number
function M.floor(value)
  return flib_math.floor(value)
end

--- Max wrapper backed by FLib's math extension.
-- @param a number
-- @param b number
-- @return number
function M.max(a, b)
  return flib_math.max(a, b)
end

--- Min wrapper backed by FLib's math extension.
-- @param a number
-- @param b number
-- @return number
function M.min(a, b)
  return flib_math.min(a, b)
end

return M
