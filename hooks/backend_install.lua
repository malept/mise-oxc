local archiver = require("archiver")
local file = require("file")
local gh = require("lib/gh")
local helpers = require("lib/helpers")
local os = require("os")
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

local function determineArch()
  if RUNTIME.archType == "amd64" then
    return "x64"
  elseif RUNTIME.archType ~= "arm64" then
    error("Unsupported CPU architecture: " .. RUNTIME.archType)
  else
    return RUNTIME.archType
  end
end

local function determineLibc()
  -- TODO determine musl vs glibc with an environment variable fallback
  return "gnu"
end

local function determineBasename(tool)
  local parts = { tool, determineOS(), determineArch() }
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
  local basename = determineBasename(ctx.tool)
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
