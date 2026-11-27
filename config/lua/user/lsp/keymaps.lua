local M = {}

-- Telescope inherits the established layout, preview, selection and resume UX.
local function picker(name)
  return function() require("telescope.builtin")[name]() end
end

local mappings = {
  { "n", "gd", "textDocument/definition", picker("lsp_definitions"), "Go to definition" },
  { "n", "gD", "textDocument/declaration", vim.lsp.buf.declaration, "Go to declaration" },
  { "n", "gr", "textDocument/references", picker("lsp_references"), "Find references" },
  { "n", "gi", "textDocument/implementation", picker("lsp_implementations"), "Go to implementation" },
  { "n", "gy", "textDocument/typeDefinition", picker("lsp_type_definitions"), "Go to type definition" },
  { "n", "K", "textDocument/hover", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover documentation" },
  { "i", "<C-k>", "textDocument/signatureHelp", function()
    vim.lsp.buf.signature_help({ border = "rounded" })
  end, "Signature help" },
  { "n", "<leader>la", "textDocument/codeAction", vim.lsp.buf.code_action, "LSP code action" },
  { "x", "<leader>la", "textDocument/codeAction", vim.lsp.buf.code_action, "LSP range code action" },
  { "n", "<leader>lr", "textDocument/rename", vim.lsp.buf.rename, "Rename symbol" },
  { "n", "<leader>lS", "workspace/symbol", picker("lsp_workspace_symbols"), "Search workspace symbols" },
}

function M.refresh(bufnr, excluded_client)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  for _, mapping in ipairs(mappings) do
    local mode, lhs, method, action, desc = unpack(mapping)
    local supported = false
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if client.id ~= excluded_client and client:supports_method(method, bufnr) then
        supported = true
        break
      end
    end
    if supported then
      vim.keymap.set(mode, lhs, action, {
        buffer = bufnr, desc = desc,
        -- Plain gr deliberately takes precedence over native gr* defaults.
        nowait = lhs == "gr",
      })
    else
      -- Restore native motions after detach; do not delete a project override.
      for _, existing in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
        if existing.desc == desc then
          vim.keymap.del(mode, lhs, { buffer = bufnr })
          break
        end
      end
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event) M.refresh(event.buf) end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    callback = function(event) M.refresh(event.buf, event.data.client_id) end,
  })
end

return M
