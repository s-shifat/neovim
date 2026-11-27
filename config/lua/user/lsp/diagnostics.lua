local M = {}

local severity = vim.diagnostic.severity
local config = {
  signs = {
    text = {
      [severity.ERROR] = "",
      [severity.WARN] = "",
      [severity.INFO] = "",
      [severity.HINT] = "󰌵",
    },
  },
  underline = true,
  virtual_text = false,
  virtual_lines = false,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many", scope = "line" },
}

function M.setup()
  vim.diagnostic.config(config)
  vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
  vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, { desc = "Previous diagnostic" })
  vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, { desc = "Next diagnostic" })
end

return M
