local M = {}

local noise_directories = {
  ".git",
  ".venv",
  "venv",
  "env",
  "__pycache__",
  ".pytest_cache",
  ".mypy_cache",
  ".ruff_cache",
  ".ipynb_checkpoints",
  "node_modules",
}

local lock_files = {
  "lazy-lock.json",
  "poetry.lock",
  "package-lock.json",
  "yarn.lock",
  "pnpm-lock.yaml",
  "Cargo.lock",
}

local ignore_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  .. "/telescope.ignore"

local function fd_command(include_ignored)
  local command = { "fd", "--type", "f", "--hidden", "--strip-cwd-prefix" }

  if include_ignored then
    table.insert(command, "--no-ignore")
    return command
  end

  vim.list_extend(command, { "--ignore-file", ignore_file })

  return command
end

local function rg_exclusions()
  -- An ignore file remains authoritative when users add positive --glob
  -- arguments, unlike earlier --glob exclusions which ripgrep can re-include.
  return { "--hidden", "--ignore-file", ignore_file }
end

local function git_root(cwd)
  local result = vim.system(
    { "git", "-C", cwd, "rev-parse", "--show-toplevel" },
    { text = true }
  ):wait()

  if result.code == 0 then
    return vim.trim(result.stdout)
  end
end

local function project_root()
  return git_root(vim.fn.getcwd()) or vim.fn.getcwd()
end

local function find_files(opts)
  opts = opts or {}
  require("telescope.builtin").find_files(vim.tbl_extend("force", {
    find_command = fd_command(false),
    hidden = true,
  }, opts))
end

function M.project_files()
  local cwd = project_root()
  local in_git = git_root(cwd) ~= nil

  if not in_git then
    find_files({ cwd = cwd, prompt_title = "Files in " .. vim.fn.fnamemodify(cwd, ":t") })
    return
  end

  local command = {
    "git", "ls-files", "--cached", "--others", "--exclude-standard", "--deduplicate", "--",
    ".",
  }

  for _, name in ipairs(noise_directories) do
    table.insert(command, ":(exclude)" .. name .. "/**")
    table.insert(command, ":(exclude)**/" .. name .. "/**")
  end

  for _, name in ipairs(lock_files) do
    table.insert(command, ":(exclude)" .. name)
    table.insert(command, ":(exclude)**/" .. name)
  end

  local ok = pcall(require("telescope.builtin").git_files, {
    cwd = cwd,
    git_command = command,
    prompt_title = "Project Files",
  })

  if not ok then
    find_files({ cwd = cwd, prompt_title = "Project Files" })
  end
end

function M.files()
  find_files({ cwd = vim.fn.getcwd(), prompt_title = "Files" })
end

function M.live_grep_args(include_ignored)
  local extra = include_ignored and { "--hidden", "--no-ignore" } or rg_exclusions()
  require("telescope").extensions.live_grep_args.live_grep_args({
    cwd = project_root(),
    additional_args = function()
      return extra
    end,
    prompt_title = include_ignored and "Live Grep (including ignored files)" or "Live Grep",
  })
end

local function visual_selection()
  local lines = vim.fn.getregion(
    vim.fn.getpos("v"),
    vim.fn.getpos(".")
  )

  return table.concat(lines, " ")
end

function M.grep_word(search)
  require("telescope.builtin").grep_string({
    cwd = project_root(),
    search = search,
    additional_args = rg_exclusions,
  })
end

local function config_source()
  if vim.g.neovim_config_source and vim.fn.isdirectory(vim.g.neovim_config_source) == 1 then
    return vim.g.neovim_config_source
  end

  local cwd = project_root()
  if vim.fn.filereadable(cwd .. "/flake.nix") == 1
      and vim.fn.isdirectory(cwd .. "/config/lua/user") == 1 then
    return cwd .. "/config"
  end

  -- In a packaged editor this is the actual immutable config runtime. When the
  -- source checkout is the cwd, the branch above deliberately prefers it.
  return vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h:h")
end

function M.setup()
  local builtin = require("telescope.builtin")
  local map = vim.keymap.set

  map("n", "<leader>sp", M.project_files, { desc = "Search project files" })
  map("n", "<leader>sf", M.files, { desc = "Search files from cwd" })
  map("n", "<leader>st", M.live_grep_args, { desc = "Search text with ripgrep arguments" })
  map("n", "<leader>sw", function() M.grep_word(vim.fn.expand("<cword>")) end, { desc = "Search current word" })
  map("x", "<leader>sw", function() M.grep_word(visual_selection()) end, { desc = "Search selected text" })
  map("n", "<leader>s/", function()
    builtin.live_grep({ grep_open_files = true, prompt_title = "Search Open Files" })
  end, { desc = "Search within open files" })
  map("n", "<leader>sb", builtin.buffers, { desc = "Search open buffers" })
  map("n", "<leader>sr", builtin.resume, { desc = "Resume last Telescope picker" })
  map("n", "<leader>s.", builtin.oldfiles, { desc = "Search recent files" })
  map("n", "<leader>sh", builtin.help_tags, { desc = "Search help tags" })
  map("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
  map("n", "<leader>ss", builtin.builtin, { desc = "Search Telescope builtins" })
  map("n", "<leader>sn", function()
    find_files({ cwd = config_source(), prompt_title = "Neovim Configuration" })
  end, { desc = "Search Neovim configuration" })
  map("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
  map("n", "<leader>sua", function()
    builtin.find_files({ cwd = project_root(), find_command = fd_command(true), hidden = true })
  end, { desc = "Search all files including ignored" })
  map("n", "<leader>sug", function() M.live_grep_args(true) end, { desc = "Search ignored text with arguments" })
end

M.project_root = project_root
M.fd_command = fd_command
M.rg_exclusions = rg_exclusions
M.config_source = config_source

return M
