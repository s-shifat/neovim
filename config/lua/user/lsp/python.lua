local M = {}

-- python.pythonPath in a trusted .nvim.lua takes priority over discovery.
function M.before_init(_, config)
  config.settings = config.settings or {}
  config.settings.python = config.settings.python or {}
  if config.settings.python.pythonPath
      and config.settings.python.pythonPath ~= config._user_discovered_python then
    return
  end

  -- Native restart reuses the config. Re-discover an automatic selection while
  -- preserving a path supplied by a trusted project/user override.
  config.settings.python.pythonPath = nil
  config._user_discovered_python = nil

  local candidates = {
    vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python") or "",
    vim.env.CONDA_PREFIX and (vim.env.CONDA_PREFIX .. "/bin/python") or "",
    config.root_dir and (config.root_dir .. "/.venv/bin/python") or "",
    vim.fn.exepath("python3"),
    vim.fn.exepath("python"),
  }
  for _, path in ipairs(candidates) do
    if path ~= "" and vim.fn.executable(path) == 1 then
      config.settings.python.pythonPath = path
      config._user_discovered_python = path
      return
    end
  end
end

return M
