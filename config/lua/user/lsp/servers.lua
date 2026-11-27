-- nvim-lspconfig supplies filetypes, root markers and server protocol defaults.
-- These overrides express project policy; specialized workflows come later.
return {
  lua_ls = {
    before_init = require("user.lsp.lua").before_init,
    settings = { Lua = { telemetry = { enable = false } } },
  },
  nixd = {
    -- Return an object for workspace/configuration; nixd rejects null defaults.
    settings = { nixd = vim.empty_dict() },
  },
  bashls = {}, -- Keep upstream's bounded scan and optional tool discovery.
  basedpyright = {
    before_init = require("user.lsp.python").before_init,
    settings = { basedpyright = { analysis = { diagnosticMode = "openFilesOnly" } } },
  },
  jsonls = {
    -- Use the Nix-owned executable, not a node_modules server chosen upstream.
    cmd = { "vscode-json-language-server", "--stdio" },
    settings = { json = { validate = { enable = true } } },
  },
  yamlls = {
    cmd = { "yaml-language-server", "--stdio" },
    settings = { yaml = { validate = true, hover = true, completion = true } },
  },
  taplo = {}, -- Honors taplo.toml/.taplo.toml.
  marksman = {}, -- Honors .marksman.toml; single documents also attach.
  texlab = {
    settings = {
      texlab = {
        build = { onSave = false }, -- Compiler orchestration is a later stage.
        chktex = { onOpenAndSave = false, onEdit = false },
      },
    },
  },
}
