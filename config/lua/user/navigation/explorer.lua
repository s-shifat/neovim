local M = {}


local function snacks()
  local ok, module = pcall(require, "snacks")

  if not ok then
    vim.notify("Snacks Explorer is unavailable", vim.log.levels.WARN)
    return
  end

  return module
end

local function explorer()
  local module = snacks()
  return module and module.picker.get({ source = "explorer" })[1]
end

local function options()
  return {
    cwd = require("user.navigation.search").project_root(),
  }
end

function M.snacks_config()
  return {
    explorer = {
      enabled = true,
      replace_netrw = true,
    },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          auto_close = false,
          diagnostics = true,
          focus = "list",
          follow_file = true,
          git_status = true,
          hidden = true,
          ignored = true,
          jump = { close = false },
          layout = {
            preview = false,
            layout = {
              position = "left",
              width = 40,
            },
          },
          win = {
            list = {
              keys = {
                ["<S-CR>"] = { { "pick_win", "jump" } },
                ["<leader>/"] = false,
                ["<c-t>"] = false,
                B = "edit_split",
                V = "edit_vsplit",
              },
            },
          },
        },
      },
    },
  }
end

function M.toggle()
  local current = explorer()

  if current then
    if current:is_focused() then
      current:close()
    else
      current:focus("list")
    end
    return
  end

  local module = snacks()
  if module then
    module.explorer.open(options())
  end
end

function M.reveal()
  local module = snacks()
  if not module then
    return
  end

  local current = explorer()
  if not current then
    local opts = options()
    opts.on_show = function(picker)
      module.explorer.reveal()
      picker:focus("list")
    end
    module.explorer.open(opts)
    return
  end

  module.explorer.reveal()
  current:focus("list")
end

function M.setup()
  vim.keymap.set("n", "<leader>e", M.toggle, {
    desc = "Toggle or focus file explorer",
  })
end


return M
