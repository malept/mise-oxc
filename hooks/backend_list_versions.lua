local helpers = require("lib/helpers")

-- Why: ignoring "unused argument: self"
-- luacheck: ignore 212
function PLUGIN:BackendListVersions(ctx)
  local allVersions = helpers.cachedReleaseVersions()

  local versions = {}
  local toolVersionMap = allVersions[ctx.tool]

  if toolVersionMap ~= nil then
    for version, _ in pairs(toolVersionMap) do
      table.insert(versions, version)
    end
  end

  table.sort(versions)

  return { versions = versions }
end
