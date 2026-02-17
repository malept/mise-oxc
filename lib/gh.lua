local M = {}

local cmd = require("cmd")
local strings = require("strings")
local ghPath = nil

--- Determines whether `gh` is available in `PATH`.
---@return string # Path to `gh`
local function find()
  local success, output = pcall(cmd.exec, "command -v gh")
  if not success then
    print(output)
    error("Could not find gh in PATH, make sure it's installed: mise use --global github-cli")
  end

  return output
end

--- Runs `gh` with the given predicate (subcommand and/or flags).
---@param predicate string the subcommand(s) and/or flags to pass to `gh`
---@return boolean success # Whether the command succeeded
---@return string output # The stdout value from the command
function M.run(predicate)
  -- Can't call `mise exec github-cli -- gh [...]` because it's an endless loop
  if ghPath == nil then
    ghPath = find()
  end

  return pcall(cmd.exec, ("%q %s"):format(ghPath, predicate))
end

--- GitHub repository identifier (owner/name).
---@return string
function M.repoIdentifier()
  return "oxc-project/oxc"
end

--- GitHub repository identifier, except split by slash (`/`).
---@return string[]
function M.repoIdentifierParts()
  return strings.split(M.repoIdentifier(), "/")
end

--- Runs `gh release` for the repo.
---@param predicate string the subcommand(s) and/or flags to pass to `gh release`
---@return boolean success # Whether the subcommand succeeded
---@return string output # The stdout value from the subcommand
function M.release(predicate)
  local ghPredicate = ("release --repo %q %s"):format(M.repoIdentifier(), predicate)
  return M.run(ghPredicate)
end

--- Runs `gh release list` for the repo.
---@param predicate string the subcommand(s) and/or flags to pass to `gh release list`
---@return boolean success # Whether the subcommand succeeded
---@return string output # The stdout value from the subcommand
function M.listReleases(predicate)
  return M.release("list " .. predicate)
end

--- Runs `gh release view` for the repo.
---@param tag string the git tag associated with the release
---@param predicate string the subcommand(s) and/or flags to pass to `gh release list`
---@return boolean success # Whether the subcommand succeeded
---@return string output # The stdout value from the subcommand
function M.getRelease(tag, predicate)
  return M.release(("view %q %s"):format(tag, predicate))
end

--- Downloads a release artifact.
---@param tag string the git tag associated with the release
---@param filename string the filename of the release artifact
---@param downloadDir string the directory path to download the artifact to
---@return boolean success # Whether the subcommand succeeded
---@return string output # The stdout value from the subcommand
function M.downloadArtifact(tag, filename, downloadDir)
  return M.release(("download %q --pattern %q --dir %q"):format(tag, filename, downloadDir))
end

return M
