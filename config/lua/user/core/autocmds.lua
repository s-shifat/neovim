local api = vim.api

-- ============================================================================
-- YANK FEEDBACK
-- ============================================================================

local highlight_yank_group = api.nvim_create_augroup(
  "UserHighlightYank",
  { clear = true }
)

api.nvim_create_autocmd("TextYankPost", {
  group = highlight_yank_group,
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.hl.hl_op({
      higroup = "Search",
      timeout = 100,
    }) -- Flash the copied region so a yank has immediate visual confirmation.
  end,
})


-- ============================================================================
-- CLOSE TEMPORARY CORE WINDOWS WITH q
-- ============================================================================

local close_special_group = api.nvim_create_augroup(
  "UserCloseSpecialBuffers",
  { clear = true }
)

api.nvim_create_autocmd("FileType", {
  group = close_special_group,
  pattern = {
    "checkhealth",
    "help",
    "man",
    "qf",
  },
  desc = "Allow q to close temporary core windows",
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Close temporary window",
    }) -- Make q dismiss help/man/health/quickfix windows without affecting normal files.
  end,
})


-- ============================================================================
-- KEEP SPLITS BALANCED WHEN THE OUTER TERMINAL RESIZES
-- ============================================================================

local resize_group = api.nvim_create_augroup(
  "UserEqualizeSplits",
  { clear = true }
)

api.nvim_create_autocmd("VimResized", {
  group = resize_group,
  desc = "Equalize splits after terminal resize",
  callback = function()
    local current_tab = api.nvim_get_current_tabpage()

    vim.cmd("tabdo wincmd =") -- Rebalance window sizes in every tabpage after the terminal changes size.

    if api.nvim_tabpage_is_valid(current_tab) then
      api.nvim_set_current_tabpage(current_tab)
    end -- Return to the tabpage that was active before the rebalance.
  end,
})


-- ============================================================================
-- DEFERRED AUTOMATIC BEHAVIOR
-- ============================================================================
--
-- Format-on-save:
--   Added with the formatting architecture, not in the core editor.
--
-- LSP attach/startup:
--   Added with the native LSP stage.
--
-- Lua-specific gf behavior:
--   Added during the Lua language vertical slice if still useful.
--
-- Plugin startup events:
--   Added only by the features that need them.
