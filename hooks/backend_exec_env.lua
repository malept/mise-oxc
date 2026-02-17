-- Why: ignoring "unused argument: self"
-- luacheck: ignore 212
function PLUGIN:BackendExecEnv(ctx)
  return {
    env_vars = {
      { key = "PATH", value = ctx.install_path },
    },
  }
end
