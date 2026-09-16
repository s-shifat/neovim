local M = {}


-- ============================================================================
-- SNACKS NOTIFICATIONS
-- ============================================================================

function M.setup()
  local native_notify = vim.notify
  local ok, snacks = pcall(require, "snacks")

  if not ok then
    native_notify(
      "Snacks is unavailable; using native notifications",
      vim.log.levels.WARN
    )
    return
  end

  local explorer = require("user.navigation.explorer").snacks_config()
  local image_view = require("user.ui.image")
  local image = image_view.snacks_config()
  image_view.setup()
  local setup_ok, setup_error = pcall(snacks.setup, vim.tbl_deep_extend("force", {
    notifier = {
      enabled = true,
      timeout = 3000,
      style = "compact",
      top_down = true,
    },

    styles = {
      notification = {
        focusable = false,
        wo = {
          wrap = true,
        },
      },
    },

    -- Unused modules with automatic setup lifecycles remain off. Other
    -- Snacks utilities (terminal, lazygit, gitbrowse, scratch, and zen) are
    -- on-demand only and receive no mappings or configuration.
    bigfile = { enabled = false },
    dashboard = { enabled = false },
    indent = { enabled = false },
    input = { enabled = false },
    quickfile = { enabled = false },
    scope = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
  }, explorer, image))

  if not setup_ok then
    vim.notify = native_notify
    native_notify(
      "Snacks could not initialize; using native notifications: "
        .. tostring(setup_error),
      vim.log.levels.WARN
    )
    return
  end

  vim.keymap.set("n", "<leader>nh", function()
    snacks.notifier.show_history()
  end, { desc = "Show notification history" })

  vim.keymap.set("n", "<leader>nd", function()
    snacks.notifier.hide()
  end, { desc = "Dismiss notifications" })
end


return M
