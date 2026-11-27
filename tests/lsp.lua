-- Actual server processes, project roots and protocol behavior; bounded waits.
local root = assert(vim.env.NVIM_LSP_TEST_ROOT) .. "/project"
local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(vim.split(contents, "\n"), path)
end
local function check(condition, message)
  assert(condition, message)
end
local function wait_for(predicate, message)
  if not vim.wait(20000, predicate, 50) then
    print(vim.inspect(vim.tbl_map(function(client)
      return { id = client.id, name = client.name, initialized = client.initialized, buffers = client.attached_buffers }
    end, vim.lsp.get_clients())))
    print(table.concat(vim.fn.readfile(vim.lsp.log.get_filename()), "\n"):sub(-5000))
    error(message)
  end
end
local function log(message)
  print("neovim-lsp: " .. message)
end
local function request(client, buf, method, params)
  local response, err = client:request_sync(method, params, 10000, buf)
  check(response ~= nil and not response.err,
    method .. ": " .. vim.inspect(response and response.err or err))
  return response.result
end
local function position(buf, line, character)
  return { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = line, character = character } }
end

local function run()
  check(vim.g.neovim_config_loaded, "configuration failed to load")
  write(root .. "/.git/HEAD", "ref: refs/heads/main")
  write(root .. "/flake.nix", "{ outputs = _: {}; }")
  write(root .. "/config/lua/user/init.lua", "return {}")
  write(root .. "/helper.nix", "{ value = 42; }")
  write(root .. "/pyproject.toml", '[project]\nname = "lsp-fixture"\nversion = "0.1.0"')
  local samples = {
    { "lua_ls", "sample.lua", "local function answer(value)\n  return value + 1\nend\nlocal result = answer(41)\nprint(missing_global)\nprint(answer(10))" },
    { "nixd", "sample.nix", "{ answer = missing_variable; helper = import ./helper.nix; }" },
    { "bashls", "sample.sh", "#!/usr/bin/env bash\nfunction answer() { echo hello; }\nanswer\nif then" },
    { "basedpyright", "sample.py", "def answer(value: int) -> int:\n    return value + 1\n\nresult = answer(41)\nwrong: int = 'bad'\nfrom stage10_environment import environment_value\nprint(environment_value)" },
    { "jsonls", "sample.json", '{"value": }' },
    { "yamlls", "sample.yaml", "value: 1\nvalue: 2" },
    { "taplo", "sample.toml", "value = 1\nvalue = 2" },
    { "marksman", "sample.md", "# Heading\n\n[Missing](nonexistent.md)" },
    { "texlab", "sample.tex", "\\documentclass{article}\n\\begin{document}\n\\section{Heading}\n\\ref{missing}\n\\end{document}" },
  }
  local attached = {}
  for _, sample in ipairs(samples) do
    local name, filename, contents = unpack(sample)
    local config = vim.lsp.config[name]
    check(vim.fn.executable(config.cmd[1]) == 1, name .. " executable unavailable")
    check(config.cmd_env.XDG_CACHE_HOME == vim.fn.stdpath("cache") .. "/lsp", name .. " cache escapes editor identity")
    check(config.cmd_env.XDG_STATE_HOME == vim.fn.stdpath("state") .. "/lsp", name .. " state escapes editor identity")
    write(root .. "/" .. filename, contents)
    vim.cmd.edit(root .. "/" .. filename)
    local buf = vim.api.nvim_get_current_buf()
    local client
    wait_for(function()
      client = vim.lsp.get_clients({ bufnr = buf, name = name })[1]
      return client and client.initialized
    end, name .. " failed to initialize and attach")
    check(client.root_dir == root, name .. " incorrect project root: " .. tostring(client.root_dir))
    check(#vim.lsp.get_clients({ bufnr = buf }) == 1, name .. " duplicate clients")
    wait_for(function() return #vim.diagnostic.get(buf) > 0 end, name .. " did not publish real diagnostics")
    attached[name] = { client = client, buf = buf }
    log(name .. " initialized, project root and diagnostics OK")
  end

  local python = attached.basedpyright
  check(python.client.config.settings.python.pythonPath == root .. "/.venv/bin/python", "project .venv not selected")
  local import_definition = request(python.client, python.buf, "textDocument/definition", position(python.buf, 5, 37))
  check(import_definition and vim.inspect(import_definition):find("site%-packages/stage10_environment.py"), "Python project environment import did not resolve")
  log("Python project .venv import resolution OK")

  local lua = attached.lua_ls
  check(vim.tbl_contains(lua.client.settings.Lua.workspace.library, vim.env.VIMRUNTIME), "Neovim Lua workspace types unavailable")
  check(vim.lsp.semantic_tokens.is_enabled({ bufnr = lua.buf })
    and vim.treesitter.highlighter.active[lua.buf], "semantic tokens and Treesitter did not coexist")
  local nix = attached.nixd
  local nix_definition = request(nix.client, nix.buf, "textDocument/definition", position(nix.buf, 0, 49))
  check(nix_definition and vim.inspect(nix_definition):find("helper.nix", 1, true), "Nix workspace import definition missing")
  log("Lua runtime library and Nix workspace import navigation OK")
  vim.api.nvim_set_current_buf(lua.buf)
  local hover = request(lua.client, lua.buf, "textDocument/hover", position(lua.buf, 3, 17))
  check(hover and hover.contents, "Lua hover empty")
  local definition = request(lua.client, lua.buf, "textDocument/definition", position(lua.buf, 3, 17))
  check(definition and not vim.tbl_isempty(definition), "Lua definition empty")
  local references_params = position(lua.buf, 0, 17)
  references_params.context = { includeDeclaration = true }
  local references = request(lua.client, lua.buf, "textDocument/references", references_params)
  check(references and #references >= 2, "Lua references missing declaration/use")
  local rename_params = position(lua.buf, 0, 17)
  rename_params.newName = "renamed_answer"
  local edit = request(lua.client, lua.buf, "textDocument/rename", rename_params)
  check(edit and (edit.changes or edit.documentChanges), "Lua rename did not return edits")
  vim.lsp.util.apply_workspace_edit(edit, lua.client.offset_encoding)
  check(vim.api.nvim_buf_get_lines(lua.buf, 0, 1, false)[1]:find("renamed_answer"), "rename edits not applied")
  vim.bo[lua.buf].modified = false
  local action_params = {
    textDocument = { uri = vim.uri_from_bufnr(lua.buf) },
    range = { start = { line = 4, character = 6 }, ["end"] = { line = 4, character = 20 } },
    context = { diagnostics = vim.tbl_map(function(diagnostic)
      return diagnostic.user_data.lsp
    end, vim.diagnostic.get(lua.buf, { lnum = 4 })) },
  }
  local actions = request(lua.client, lua.buf, "textDocument/codeAction", action_params)
  check(actions and #actions > 0, "Lua code actions empty")
  log("Lua hover, definition, references, applied rename and code actions OK")

  local function mapping(lhs, mode)
    return vim.fn.maparg(lhs, mode or "n", false, true)
  end
  check(mapping("gd").buffer == 1 and mapping("gr").nowait == 1, "attach-time navigation mappings missing")
  check(mapping("<C-k>", "i").desc == "Signature help", "Insert signature mapping missing")
  check(mapping("<C-k>").desc:lower():find("split"), "normal split navigation changed")
  check(mapping("<leader>sy").desc == "Search document symbols", "Aerial mapping changed")
  check(mapping("<leader>ss").desc == "Search Telescope builtins", "Telescope namespace changed")
  check(mapping("<leader>sd").desc == "Search diagnostics", "diagnostics picker changed")

  local aerial = require("aerial")
  aerial.sync_load()
  wait_for(function()
    return require("aerial.backends").get_attached_backend(lua.buf) == "lsp"
      and #require("aerial.data").get_or_create(lua.buf).items > 0
  end, "Aerial did not switch to LSP symbols")
  aerial.open({ focus = false })
  check(aerial.is_open(), "outline did not open")
  aerial.close()
  log("LSP-backed Aerial and existing mappings OK")

  -- Exercise the actual mapped picker, keeping shared preview/layout/resume.
  vim.api.nvim_win_set_cursor(0, { 1, 18 })
  mapping("gr").callback()
  local picker
  wait_for(function()
    picker = require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
    return picker and picker.manager and picker.manager:num_results() >= 1
  end, "mapped Telescope references picker missing results")
  check(picker.layout_strategy == "flex" and picker.previewer, "LSP picker lost shared layout/preview")
  require("telescope.actions").close(picker.prompt_bufnr)
  mapping("<leader>sr").callback()
  wait_for(function()
    picker = require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
    return picker and picker.manager and picker.manager:num_results() >= 1
  end, "Telescope references resume failed")
  require("telescope.actions").close(picker.prompt_bufnr)
  vim.api.nvim_set_current_buf(lua.buf)
  log("mapped Telescope LSP references, preview and resume OK")

  -- Restart the current client via the native command and verify reattachment.
  local old_id = lua.client.id
  vim.api.nvim_set_current_buf(lua.buf)
  log("restarting lua_ls " .. old_id .. " from buffer " .. vim.api.nvim_get_current_buf())
  vim.cmd("lsp restart")
  wait_for(function()
    local client = vim.lsp.get_clients({ name = "lua_ls", bufnr = lua.buf })[1]
    return client and client.id ~= old_id and client.initialized
  end, "native restart did not reattach")
  check(#vim.lsp.get_clients({ name = "lua_ls", bufnr = lua.buf }) == 1, "restart duplicated client")
  vim.lsp.enable("lua_ls", false)
  wait_for(function() return #vim.lsp.get_clients({ name = "lua_ls", bufnr = lua.buf }) == 0 end,
    "Lua client failed to detach")
  aerial.sync_load()
  wait_for(function() return require("aerial.backends").get_attached_backend(lua.buf) == "treesitter" end,
    "Aerial did not fall back after LSP detach")
  check(mapping("gi").buffer ~= 1 and mapping("K").buffer ~= 1, "LSP mappings remained after detach")

  -- Native restart reuses config; automatic Python selection must be refreshed.
  vim.env.VIRTUAL_ENV = vim.env.NVIM_LSP_TEST_ROOT .. "/active-env"
  local python_id = python.client.id
  vim.cmd("lsp restart basedpyright")
  wait_for(function()
    local client = vim.lsp.get_clients({ name = "basedpyright", bufnr = python.buf })[1]
    return client and client.id ~= python_id and client.initialized
      and client.config.settings.python.pythonPath == vim.env.VIRTUAL_ENV .. "/bin/python"
  end, "Python restart did not refresh activated environment")

  -- A single file outside all project roots must still attach.
  local lone = vim.env.NVIM_LSP_TEST_ROOT .. "/single/lone.py"
  vim.env.VIRTUAL_ENV = vim.env.NVIM_LSP_TEST_ROOT .. "/active-env"
  write(lone, "from stage10_environment import environment_value\nprint(environment_value)")
  vim.cmd.edit(lone)
  local lone_buf = vim.api.nvim_get_current_buf()
  wait_for(function() return #vim.lsp.get_clients({ bufnr = lone_buf, name = "basedpyright" }) == 1 end,
    "single-file Python did not attach")
  check(vim.lsp.get_clients({ bufnr = lone_buf })[1].id ~= attached.basedpyright.client.id, "single file reused unrelated project")
  local active = vim.lsp.get_clients({ bufnr = lone_buf })[1]
  check(active.config.settings.python.pythonPath == vim.env.VIRTUAL_ENV .. "/bin/python", "activated environment not selected")
  local active_definition = request(active, lone_buf, "textDocument/definition", position(lone_buf, 0, 37))
  check(active_definition and vim.inspect(active_definition):find("active%-env/"), "activated environment import did not resolve")
  vim.env.VIRTUAL_ENV = nil

  -- Preserve explicit interpreter settings even with another activated env.
  local override = { root_dir = root, settings = { python = { pythonPath = "/explicit/python" } } }
  require("user.lsp.python").before_init({}, override)
  check(override.settings.python.pythonPath == "/explicit/python", "explicit Python override lost")
  vim.env.CONDA_PREFIX = vim.env.NVIM_LSP_TEST_ROOT .. "/active-env"
  local conda = { root_dir = root }
  require("user.lsp.python").before_init({}, conda)
  check(conda.settings.python.pythonPath == vim.env.CONDA_PREFIX .. "/bin/python", "Conda selection lost")
  vim.env.CONDA_PREFIX = nil

  write(root .. "/unsupported.csv", "name,value\none,1")
  vim.cmd.edit(root .. "/unsupported.csv")
  check(#vim.lsp.get_clients({ bufnr = 0 }) == 0, "CSV unexpectedly attached")
  check(vim.fn.maparg("gi", "n", false, true).buffer ~= 1, "LSP motion leaked to unsupported buffer")
  vim.api.nvim_buf_set_lines(0, 1, 2, false, { "two,2" })
  vim.bo.modified = false
  log("restart, isolated single-file mode and unsupported editable buffers OK")

  -- Trust only a generated fixture. A second startup verifies real exrc ordering.
  local project_config = root .. "/.nvim.lua"
  write(project_config, string.format([[
vim.g.stage10_project_override = true
vim.lsp.config("basedpyright", {
  settings = { python = { pythonPath = %q }, basedpyright = { analysis = { diagnosticMode = "workspace" } } },
})
]], vim.env.NVIM_LSP_TEST_ROOT .. "/active-env/bin/python"))
  check(vim.secure.trust({ action = "allow", path = project_config }), "fixture trust failed")
  for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
  log("PASS")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  print("neovim-lsp: FAIL: " .. err)
  vim.cmd("cquit 1")
else
  vim.cmd("qall!")
end
