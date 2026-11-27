# Native LSP

Stage 10 uses Neovim's `vim.lsp.config()` / `vim.lsp.enable()` with Nix-owned
nvim-lspconfig defaults and executables. There are no runtime installers.
Configuration lives under `config/lua/user/lsp/`: server overrides in
`servers.lua`, interpreter discovery in `python.lua`, editor Lua types in
`lua.lua`, attach-time mappings in `keymaps.lua`, diagnostic policy in
`diagnostics.lua`, and common setup in `init.lua`.

## Servers

| Filetypes | Config | Nix package / executable | Pinned version |
| --- | --- | --- | --- |
| Lua | lua_ls | lua-language-server | 3.19.1 |
| Nix | nixd | nixd | 2.9.2 |
| Bash/sh | bashls | bash-language-server | 5.6.0 |
| Python | basedpyright | basedpyright / basedpyright-langserver | 1.39.8 |
| JSON/JSONC | jsonls | vscode-langservers-extracted / vscode-json-language-server | 1.126.04524 |
| YAML | yamlls | yaml-language-server | 1.24.0 |
| TOML | taplo | taplo | 0.10.0 |
| Markdown | marksman | marksman | 2026-02-08 |
| LaTeX/BibTeX | texlab | texlab | 5.26.0 |

Validated against Neovim 0.12.5 and nvim-lspconfig 2.11.0. No substitutions or
competing servers. The JSON package contains other servers, which are not enabled.
CSV has no LSP. Upstream configs supply language-specific project markers;
all nine allow native single-file operation without a detected root.

## Actions

Mappings requiring a server capability are buffer-local and installed on
`LspAttach`. They are removed when the last supporting client detaches.

| Mapping | Action |
| --- | --- |
| `gd` / `gD` | Definition via Telescope / native declaration |
| `gr` / `gi` / `gy` | Telescope references / implementations / type definitions |
| `K` | Hover |
| Insert `<C-k>` | Signature help |
| `<leader>la` | Code action (also Visual range) |
| `<leader>lr` | Rename |
| `<leader>lS` | Telescope workspace symbols |
| `<leader>ld` | Line diagnostic float |
| `<leader>li` | Native LSP health and information |
| `<leader>ls` | Native restart of clients attached to this buffer |
| `[d` / `]d` | Previous / next diagnostic with float |

`<leader>o` remains the outline toggle; `<leader>sy` searches document symbols
through Aerial. Aerial prefers capable LSP clients and falls back to Treesitter.
`<leader>sd` remains Telescope diagnostics, `<leader>ss` builtin discovery.
Telescope keeps its shared layout, previews, interaction and resume behavior.

The requested `gi` replaces Vim's return-to-insert motion only in supporting
buffers. Plain `gr` uses `nowait` to preserve immediate historical references
navigation, taking precedence over Neovim's `gr*` mapping family in those buffers.
Normal/terminal split navigation and Telescope's `<C-k>` remain unchanged.
Other native LSP defaults, including Insert `<C-s>`, remain available.

Diagnostics use severity icons, underlines and sorting, with no virtual text or
virtual lines and no Insert-mode updates. Native semantic tokens remain enabled
where supported alongside Treesitter. Lualine already supplies diagnostic counts
and its compact `LSP` indicator; Snacks already handles notifications.

## Projects and Python

Open Neovim from the project's shell/devShell/activated environment. Server
processes inherit `PATH`, `VIRTUAL_ENV`, `CONDA_PREFIX` and project variables.
The shared Nix tools add server binaries without adding a Python interpreter or
project packages to the editor. JSON/YAML use the packaged server executable
rather than a project node_modules executable.

Python discovery, once per new client, is:

1. Explicit `settings.python.pythonPath` from configuration or trusted `.nvim.lua`.
2. Executable `$VIRTUAL_ENV/bin/python`, then `$CONDA_PREFIX/bin/python`.
3. Executable `<detected-root>/.venv/bin/python`.
4. `python3`, then `python`, on inherited `PATH` (including a Nix devShell).

No environment or dependency is created by the editor. A shell without Python
can still attach basedpyright, but project imports need an appropriate interpreter.
Restart the client after changing environments; opening another buffer in the
same root deliberately reuses the existing client. A full interpreter picker is
deferred. `pyrightconfig.json` and `[tool.basedpyright]` project settings remain
server-owned; shared defaults do not force a type-checking mode.

Trusted project `.nvim.lua` is already enabled through native `exrc`. Use
`:trust` to review/allow a project file. For example:

```lua
vim.lsp.config("basedpyright", {
  settings = {
    python = { pythonPath = vim.fn.getcwd() .. "/.venv/bin/python" },
    basedpyright = { analysis = { diagnosticMode = "workspace" } },
  },
})
-- Similarly: vim.lsp.config("nixd", { settings = { nixd = { ... } } })
```

Use absolute paths for interpreter overrides. Restart Neovim to reload changes
to the trusted project file. After calling `vim.lsp.config()` within a running
session, use `:lsp disable <name>` followed by `:lsp enable <name>` to recreate
clients from that configuration. Native `:lsp restart` reuses the existing client
config; it does rerun automatic interpreter discovery when `vim.env` changes.
For unusual root layouts override `root_markers` or `root_dir` through the same
native API. Lua `.luarc.json`/`.luarc.jsonc` takes precedence over editor-specific
LuaLS runtime/library defaults; Neovim types are added only for this editor's
configuration project or the normal Neovim config directory.

## Health and state

Use `:checkhealth vim.lsp` (or `<leader>li`) for active/enabled clients, commands
and roots. The client log is available with:

```vim
:lua vim.cmd.tabnew(vim.lsp.log.get_filename())
```

Missing executables are skipped with a notification once per server per session.
After fixing availability, use `:lsp enable <name>`. Native client startup,
attachment and process-exit reporting remains responsible for protocol failures;
there is no automatic crash/restart loop or extra progress notifier. Unsupported
buffers remain ordinary editing buffers.

The native LSP log follows `stdpath("state")`. Child servers receive XDG cache
and state directories beneath this editor's `stdpath()` paths, so LuaLS's Nix
wrapper cache/meta files and other XDG server state do not cross between `nvim`
and `nvim-next`. Project configuration and source files remain shared intentionally.

Compiler setup, formatting/linting orchestration, completion/snippets and advanced
language workflows remain scheduled for later stages. Texlab does not build on
save or run ChkTeX automatically; TeX distributions are not installed here.

Native health currently reports four upstream compound-filetype warnings
(`markdown.mdx` and three YAML variants). Ordinary Markdown/YAML attachment is
validated. Optional schema catalog fetches may log failures offline; explicit
project schemas can still be supplied without adding a schema plugin.
