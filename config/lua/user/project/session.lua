local M = {}

local config = {
  dir = vim.fn.stdpath("state") .. "/sessions/",
  need = 1,
  branch = false,
}

local persistence

local function notify(message, level)
  vim.notify("Project sessions: " .. message, level or vim.log.levels.INFO)
end

local function project_root(directory)
  if not directory then
    local buffer = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buffer)
    if vim.bo[buffer].buftype == "" and vim.bo[buffer].buflisted
        and name ~= "" and vim.fn.filereadable(name) == 1 then
      directory = vim.fn.fnamemodify(name, ":p:h")
    end
  end
  return require("user.navigation.search").project_root(directory)
end

local function enter_project(directory)
  local root = project_root(directory)
  vim.cmd.cd(vim.fn.fnameescape(root))
  return root
end

local function has_real_file()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buffer)
    if vim.bo[buffer].buftype == "" and vim.bo[buffer].buflisted
        and name ~= "" and vim.fn.filereadable(name) == 1 then
      return true
    end
  end
  return false
end

local function has_modified_files()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].buftype == "" and vim.bo[buffer].modified then
      return true
    end
  end
  return false
end

local function safe_to_load()
  if has_modified_files() then
    notify("save or resolve modified buffers before restoring a session", vim.log.levels.WARN)
    return false
  end
  return true
end

local function clear_file_buffers()
  if has_modified_files() then
    error("modified buffers appeared before session load")
  end
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buffer)
    if vim.bo[buffer].buftype == "" and name ~= ""
        and vim.fn.isdirectory(name) == 0 then
      vim.api.nvim_buf_delete(buffer, {})
    end
  end
end

local function close_explorer()
  local snacks = package.loaded.snacks
  if not snacks or not snacks.picker then return end
  local ok, pickers = pcall(snacks.picker.get, { source = "explorer" })
  if ok and pickers and pickers[1] then
    pcall(function() pickers[1]:close() end)
  end
end

local function run(action)
  if not persistence then
    notify("Persistence is unavailable", vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(action)
  if not ok then
    notify(tostring(err), vim.log.levels.ERROR)
  end
end

local function startup_kind()
  local args = vim.fn.argv()
  if #args == 0 then
    return "workspace"
  end
  if #args == 1 and vim.fn.isdirectory(args[1]) == 1 then
    return "workspace", vim.fn.fnamemodify(args[1], ":p")
  end
  return "transient"
end

function M.save()
  run(function()
    enter_project()
    if not has_real_file() then
      notify("open a real file before saving a session", vim.log.levels.WARN)
      return
    end
    persistence.save()
    persistence.start()
    notify("saved current project session")
  end)
end

function M.restore()
  if not safe_to_load() then return end
  run(function()
    local root = enter_project()
    if vim.fn.filereadable(persistence.current()) == 0 then
      notify("no saved session for " .. root)
      return
    end
    close_explorer()
    persistence.load()
    persistence.start()
    notify("restored " .. root)
  end)
end

function M.find()
  if not safe_to_load() then return end
  run(function()
    if persistence.active() and has_real_file() then
      enter_project()
      persistence.save()
    end
    persistence.select()
  end)
end

function M.delete()
  run(function()
    local root = enter_project()
    local session = persistence.current()
    if vim.fn.filereadable(session) == 0 then
      notify("no saved session for " .. root)
      return
    end
    vim.ui.select({ "Delete", "Cancel" }, {
      prompt = "Delete the saved session for " .. root .. "?",
    }, function(choice)
      if choice ~= "Delete" then return end
      if vim.fn.delete(session) == 0 then
        persistence.stop()
        notify("deleted session for " .. root)
      else
        notify("could not delete session for " .. root, vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.setup()
  vim.opt.sessionoptions = { "buffers", "curdir", "folds", "tabpages", "winsize" }

  local available, module = pcall(require, "persistence")
  if available then
    local configured, err = pcall(module.setup, config)
    if configured then
      persistence = module
      persistence.stop()

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if not has_real_file() then persistence.stop() end
        end,
      })
    else
      notify("could not initialize Persistence: " .. tostring(err), vim.log.levels.WARN)
    end
  else
    notify("Persistence is unavailable", vim.log.levels.WARN)
  end

  vim.keymap.set("n", "<leader>pf", M.find, { desc = "Project Find" })
  vim.keymap.set("n", "<leader>pr", M.restore, { desc = "Project Restore" })
  vim.keymap.set("n", "<leader>ps", M.save, { desc = "Project Save" })
  vim.keymap.set("n", "<leader>pd", M.delete, { desc = "Project Delete" })

  if not persistence then return end

  vim.api.nvim_create_autocmd("User", {
    pattern = "PersistenceLoadPre",
    callback = clear_file_buffers,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "PersistenceLoadPost",
    callback = function() persistence.start() end,
  })

  local kind, directory = startup_kind()
  if kind == "transient" then
    return
  end

  persistence.start()

  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      run(function()
        enter_project(directory)
        if vim.fn.filereadable(persistence.current()) == 1 then
          close_explorer()
          persistence.load()
        end
      end)
    end,
  })
end

return M
