local M = {}

local function make_config(actions, action_layout, themes)
  return {
    defaults = {
      initial_mode = "insert",
      path_display = { "smart" },
      prompt_prefix = "   ",
      selection_caret = " ",
      mappings = {
        i = {
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<C-n>"] = actions.move_selection_next,
          ["<C-p>"] = actions.move_selection_previous,
          ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
          ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
        },
        n = {
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<C-n>"] = actions.move_selection_next,
          ["<C-p>"] = actions.move_selection_previous,
          ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
          ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          ["q"] = actions.close,
          ["<Esc>"] = actions.close,
          -- Intentionally Normal-mode only: Space must remain query input in Insert mode.
          ["<leader>sup"] = action_layout.toggle_preview,
        },
      },
      layout_strategy = "flex",
      layout_config = {
        flex = { flip_columns = 145 },
        horizontal = { preview_width = 0.55 },
        vertical = { mirror = true, preview_height = 0.48 },
        width = 0.88,
        height = 0.80,
      },
    },
    pickers = {
      builtin = themes.get_dropdown({ previewer = false }),
      help_tags = themes.get_dropdown(),
      keymaps = themes.get_dropdown({ previewer = false }),
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
      live_grep_args = {
        -- Parse the prompt as ripgrep arguments; quote multi-word search text.
        auto_quoting = false,
      },
      ["ui-select"] = themes.get_dropdown({ previewer = false }),
    },
  }
end

local warned = false

local function warn_once(message)
  if warned then
    return
  end

  warned = true
  vim.schedule(function()
    vim.notify("Telescope: " .. message, vim.log.levels.WARN)
  end)
end

local function load_extension(telescope, name)
  local ok, err = pcall(telescope.load_extension, name)

  if not ok then
    warn_once(("could not load the %s extension: %s"):format(name, err))
  end
end

function M.setup()
  local ok, telescope = pcall(require, "telescope")

  if not ok then
    warn_once("could not initialize; basic editing remains available")
    return
  end

  local actions = require("telescope.actions")
  local action_layout = require("telescope.actions.layout")
  local themes = require("telescope.themes")

  local config = make_config(actions, action_layout, themes)
  local setup_ok, setup_error = pcall(telescope.setup, config)

  if not setup_ok then
    warn_once("setup failed: " .. tostring(setup_error))
    return
  end

  load_extension(telescope, "fzf")
  load_extension(telescope, "ui-select")
  load_extension(telescope, "live_grep_args")

  require("user.navigation.search").setup()
  vim.g.neovim_telescope_loaded = true
end

return M
