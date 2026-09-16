local M = {}

local initialized = false
local initialization_count = 0

local function notify(message)
  vim.notify("Oil: " .. message, vim.log.levels.WARN)
end

local function ensure_oil()
  if initialized then
    return package.loaded.oil
  end

  local ok, oil = pcall(require, "oil")
  if not ok then
    notify("filesystem editor is unavailable: " .. tostring(oil))
    return
  end

  local setup_ok, setup_error = pcall(oil.setup, {
    default_file_explorer = false,
    float = {
      max_width = 0.80,
      max_height = 0.75,
    },
  })

  if not setup_ok then
    notify("filesystem editor setup failed: " .. tostring(setup_error))
    return
  end

  initialized = true
  initialization_count = initialization_count + 1
  return oil
end

local function current_file_directory(bufnr)
  bufnr = bufnr or 0

  if vim.bo[bufnr].buftype ~= "" then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or vim.fn.filereadable(name) ~= 1 then
    return
  end

  return vim.fs.dirname(vim.fs.normalize(name))
end

function M.starting_directory(bufnr)
  return current_file_directory(bufnr)
    or require("user.navigation.search").project_root()
    or vim.fn.getcwd()
end

function M.toggle()
  local oil = ensure_oil()
  if not oil then
    return
  end

  local directory = vim.bo.filetype == "oil" and nil or M.starting_directory()
  local ok, open_error = pcall(oil.toggle_float, directory)
  if not ok then
    notify("could not toggle filesystem editor: " .. tostring(open_error))
  end
end

function M.setup()
  -- global mapping
  vim.keymap.set("n", "<leader>f", M.toggle, {
    desc = "Toggle Oil filesystem editor",
  })
end

function M.is_initialized()
  return initialized
end

function M.initialization_count()
  return initialization_count
end

M.ensure_oil = ensure_oil

return M
