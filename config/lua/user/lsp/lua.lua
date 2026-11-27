local M = {}

function M.before_init(_, config)
  local root = config.root_dir
  -- Project Lua settings are authoritative. Add Neovim types only for this
  -- editor's config tree, rather than treating every Lua project as a plugin.
  if not root or vim.uv.fs_stat(root .. "/.luarc.json")
      or vim.uv.fs_stat(root .. "/.luarc.jsonc") then
    return
  end
  if not vim.uv.fs_stat(root .. "/config/lua/user")
      and root ~= vim.fn.stdpath("config") then
    return
  end
  config.settings = config.settings or {}
  -- Mutate the shared settings table: Client.settings already references it.
  -- Explicit native/project settings win over these editor-specific defaults.
  config.settings.Lua = vim.tbl_deep_extend("keep", config.settings.Lua or {}, {
    runtime = { version = "LuaJIT" },
    workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
  })
end

return M
