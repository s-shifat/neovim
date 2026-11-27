local servers = require("user.lsp.servers")

require("user.lsp.diagnostics").setup()
require("user.lsp.keymaps").setup()

-- Keep native capabilities and semantic highlighting. Completion and formatting
-- remain separate stages; no automatic completion or format-on-save.
vim.lsp.config("*", {
  workspace_required = false, -- Upstream root markers with native single-file mode.
  exit_timeout = 2000, -- Bound shutdown/restart if a server does not acknowledge it.
  -- Child-server caches/logs must share the editor's application identity.
  -- In particular, the Nix LuaLS wrapper otherwise uses a shared XDG cache.
  cmd_env = {
    XDG_CACHE_HOME = vim.fn.stdpath("cache") .. "/lsp",
    XDG_STATE_HOME = vim.fn.stdpath("state") .. "/lsp",
  },
})

for name, config in pairs(servers) do
  vim.lsp.config(name, config)
  local command = vim.lsp.config[name].cmd
  if type(command) == "table" and vim.fn.executable(command[1]) == 1 then
    vim.lsp.enable(name)
  else
    vim.notify_once("LSP executable unavailable for " .. name .. "; see :checkhealth vim.lsp", vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", { desc = "LSP information and health" })
vim.keymap.set("n", "<leader>ls", "<cmd>lsp restart<cr>", { desc = "Restart language server" })
