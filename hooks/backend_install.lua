local archiver = require("archiver")
local file = require("file")
local gh = require("lib/gh")
local helpers = require("lib/helpers")
local os = require("os")
local semver = require("lib/semver")
local strings = require("strings")

local function determineOS()
  if RUNTIME.osType == "windows" then
    return "win32"
  elseif RUNTIME.osType ~= "darwin" and RUNTIME.osType ~= "linux" then
    error("Unsupported OS: " .. RUNTIME.osType)
  else
    return RUNTIME.osType
  end
end

--- After oxlint v1.43.0 and oxfmt v0.28.0, the standalone binaries supported more targets, with
--- more standardized target names.
--- See: https://github.com/oxc-project/oxc/pull/18853
---@return boolean # whether the tool + version supports expanded targets
local function expandedTargets(tool, version)
  return (tool == "oxlint" and semver.gt(version, "1.43.0")) or (tool == "oxfmt" and semver.gt(version, "0.28.0"))
end

--- Until oxlint v1.43.0 and oxfmt v0.28.0, the `amd64` arch name was x64.
--- After those versions, it is `x86_64`.
---@param tool string the tool name
---@param version string the version of the given tool
---@return string # The arch name used in the artifact
local function amd64ArchName(tool, version)
  if expandedTargets(tool, version) then
    return "x86_64"
  else
    return "x64"
  end
end

--- Determines the architecture name based on the current platform, tool, and version.
---@param tool string the tool name
---@param version string the version of the given tool
---@return string # The arch name used in the artifact
local function determineArch(tool, version)
  if expandedTargets(tool, version) then
    if RUNTIME.archType == "amd64" then
      return "x86_64"
    elseif RUNTIME.archType == "arm64" then
      return "aarch64"
    elseif RUNTIME.archType == "386" then
      return "i686"
    else
      return RUNTIME.archType
    end
  else
    if RUNTIME.archType == "amd64" then
      return "x64"
    elseif RUNTIME.archType ~= "arm64" then
      error("Unsupported CPU architecture: " .. RUNTIME.archType)
    else
      return RUNTIME.archType
    end
  end
end

local function determineVendor()
  if RUNTIME.osType == "windows" then
    return "pc"
  elseif RUNTIME.osType == "darwin" then
    return "apple"
  else
    return "unknown"
  end
end

local function determineLibc()
  -- TODO determine musl vs glibc with an environment variable fallback
  return "gnu"
end

local function determineBasename(tool, version)
  local parts = { tool }
  if expandedTargets(tool, version) then
    table.insert(parts, determineArch(tool, version))
    table.insert(parts, determineVendor())
    table.insert(parts, determineOS())
  else
    table.insert(parts, determineOS())
    table.insert(parts, determineArch(tool, version))
  end

  if RUNTIME.osType == "linux" then
    table.insert(parts, determineLibc())
  end
  return strings.join(parts, "-")
end

local function determineReleaseTag(tool, version)
  local allReleases = helpers.allReleaseVersions()
  local allVersions = allReleases[tool]
  if allVersions ~= nil and allVersions[version] ~= nil then
    return allVersions[version].tag
  end
end

-- Why: ignoring "unused argument: self"
-- luacheck: ignore 212
function PLUGIN:BackendInstall(ctx)
  local tool = ctx.tool
  local version = ctx.version
  local installDir = ctx.install_path
  local basename = determineBasename(tool, version)
  local ext

  if RUNTIME.osType == "windows" then
    ext = ".zip"
  else
    ext = ".tar.gz"
  end

  local toolArtifact = basename .. ext
  local downloadDir = ctx.download_path

  gh.downloadArtifact(determineReleaseTag(tool, version), toolArtifact, downloadDir)

  local err = archiver.decompress(file.join_path(downloadDir, toolArtifact), installDir)
  if err ~= nil then
    error("Extraction failed: " .. err)
  end

  os.rename(file.join_path(installDir, basename), file.join_path(installDir, tool))

  return {}
end
