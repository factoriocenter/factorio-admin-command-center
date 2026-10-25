-- FLib 0.17 renamed for_each to any_of. Both stop on a truthy callback result.
-- Keep the shared call sites and FLib's table unchanged on either release line.
local flib_table = require("__flib__.table")

return setmetatable({
  for_each = flib_table.any_of or flib_table.for_each,
}, { __index = flib_table })
