local M = {}

local config = {
  height = 0.30,
}

-- Future Snacks Terminal experiments may use count for multiple instances,
-- cmd for command-specific terminals, Snacks.terminal.get()/open()/focus() for
-- explicit lifecycle control, env for a scoped environment, or win.position
-- for float/left/right layouts.

local function notify(message)
  vim.notify("Snacks Terminal: " .. message, vim.log.levels.WARN)
end

local function snacks()
  local ok, module = pcall(require, "snacks")

  if not ok or type(module.terminal) ~= "table"
      or type(module.terminal.toggle) ~= "function" then
    notify("quick terminal is unavailable")
    return
  end

  return module
end

local function options()
  return {
    count = 1,
    cwd = require("user.navigation.search").project_root(),
  }
end

function M.snacks_config()
  return {
    terminal = {
      win = {
        position = "bottom",
        height = config.height,
        keys = {
          term_normal = {
            "jj",
            function() return "<C-\\><C-n>" end,
            mode = "t",
            expr = true,
            desc = "Enter terminal-normal mode",
          },
        },
      },
    },
  }
end

function M.toggle()
  local module = snacks()
  if not module then
    return
  end

  local ok, toggle_error = pcall(module.terminal.toggle, nil, options())
  if not ok then
    notify("could not toggle quick terminal: " .. tostring(toggle_error))
  end
end

function M.setup()
  local module = snacks()
  if not module then
    return
  end

  vim.keymap.set({ "n", "t" }, "<C-\\>", M.toggle, {
    desc = "Toggle quick terminal",
  })
end

M.options = options

return M
