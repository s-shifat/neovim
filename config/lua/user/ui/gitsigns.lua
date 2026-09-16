local M = {}


-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

local function warn_once(message)
  vim.notify_once(
    message,
    vim.log.levels.WARN,
    { title = "Neovim Git signs" }
  )
end


-- ============================================================================
-- BUFFER-LOCAL MAPPINGS
-- ============================================================================

local function attach_mappings(gitsigns, bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      buffer = bufnr,
      desc = desc,
      silent = true,
    })
  end

  map("n", "<leader>gj", function()
    gitsigns.nav_hunk("next")
  end, "Next Git hunk")

  map("n", "<leader>gk", function()
    gitsigns.nav_hunk("prev")
  end, "Previous Git hunk")

  map("n", "<leader>gp", gitsigns.preview_hunk, "Preview Git hunk")
  map("n", "<leader>gs", gitsigns.stage_hunk, "Stage Git hunk")
  map("n", "<leader>gr", gitsigns.reset_hunk, "Reset Git hunk")
  map("n", "<leader>gu", gitsigns.undo_stage_hunk, "Undo staged Git hunk")

  map("v", "<leader>gs", function()
    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Stage selected Git hunk")

  map("v", "<leader>gr", function()
    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Reset selected Git hunk")
end

local function make_config(gitsigns)
  return {
    signcolumn = true,
    signs_staged_enable = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    current_line_blame = false,

    on_attach = function(bufnr)
      attach_mappings(gitsigns, bufnr)
    end,
  }
end


-- ============================================================================
-- GIT SIGNS SETUP
-- ============================================================================

function M.setup()
  local available, gitsigns = pcall(require, "gitsigns")

  if not available then
    warn_once("Gitsigns is unavailable; Git-aware editing is disabled")
    return
  end

  local config = make_config(gitsigns)
  local configured, setup_err = pcall(gitsigns.setup, config)

  if not configured then
    warn_once(
      "Could not initialize Gitsigns: " .. tostring(setup_err)
    )
  end
end


return M
