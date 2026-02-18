local cache = require("lib/cache")
local gh = require("lib/gh")
local json = require("json")
local strings = require("strings")

local M = {}

local supportedTools = {
  "oxlint",
  "oxfmt",
}

--- Metadata for a given GitHub release.
---@class ReleaseVersion
---@field tag string The git tag associated with the version
---@field url string the GitHub release URL associated with the version

---@alias ReleaseVersions table<string, ReleaseVersion>
---@alias ReleaseToolVersions table<string, ReleaseVersions>

---Fetches all release versions for all supported tools.
---@return ReleaseToolVersions
function M.allReleaseVersions()
  local success, releasesJSON =
    gh.listReleases("--json name,tagName --jq '. | map(. | select(.tagName | startswith(\"apps_v\")))'")
  if not success then
    print(releasesJSON)
    error("Could not find releases for oxc")
  end

  local releases = json.decode(strings.trim_space(releasesJSON))
  local versions = {}
  for _, tool in pairs(supportedTools) do
    versions[tool] = {}
  end
  for _, release in pairs(releases) do
    for _, tool in pairs(supportedTools) do
      local start, _, version = string.find(release.name, tool .. " v([.0-9]+)")
      if start ~= nil then
        local ghrSuccess, ghr = M.cachedReleaseVersion(release.tagName)
        if not ghrSuccess then
          print(ghr)
          error("Could not find release for oxc: " .. release.tagName)
        end
        local assets = ghr["assets"]
        if assets ~= nil and #assets > 0 then
          versions[tool][version] = {
            tag = release.tagName,
            url = ghr.url,
          }
        end
      end
    end
  end

  return versions
end

---Cached version of [`allReleaseVersions`](lua://allReleaseVersions)
function M.cachedReleaseVersions()
  return cache.value(M.allReleaseVersions, "releaseVersions")
end

---@class GHReleaseVersionAsset

---@class GHReleaseVersion
---@field assets GHReleaseVersionAsset[]
---@field isImmutable boolean
---@field isPrerelease boolean
---@field publishedAt string
---@field url string

---@param tagName string The git tag name to fetch
---@return boolean
---@return GHReleaseVersion | string
function M.releaseVersion(tagName)
  local success, releaseJSON = gh.getRelease(tagName, "--json assets,isImmutable,isPrerelease,publishedAt,url")
  if success then
    return success, json.decode(strings.trim_space(releaseJSON))
  else
    return success, releaseJSON
  end
end

---@param tagName string The git tag name to fetch
---@return boolean
---@return GHReleaseVersion | string
function M.cachedReleaseVersion(tagName)
  return cache.maybeValue(M.releaseVersion, "release-version-" .. tagName, tagName)
end

return M
