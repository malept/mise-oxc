local semver = require("semver")

local M = {}

function M.gt(left, right)
  return semver.compare(left, right) == 1
end

return M
