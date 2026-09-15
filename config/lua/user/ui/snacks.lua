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

  local setup_ok, setup_error = pcall(snacks.setup, {
    -- The notifier is the only Snacks feature authorized for Stage 7E.
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

    -- These modules have automatic setup lifecycles and remain off. Other
    -- Snacks utilities (terminal, lazygit, gitbrowse, scratch, and zen) are
    -- on-demand only and receive no mappings or configuration in this stage.
    bigfile = { enabled = false },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = false },
    input = { enabled = false },
    picker = { enabled = false },
    quickfile = { enabled = false },
    scope = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
  })

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
