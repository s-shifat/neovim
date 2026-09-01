local map = vim.keymap.set
local api = vim.api

-- ============================================================================
-- LEADER KEYS
-- ============================================================================

vim.g.mapleader = " "       -- Use Space as the global leader prefix.
vim.g.maplocalleader = " "  -- Use Space as the filetype/plugin-local leader prefix.

map({ "n", "x" }, "<Space>", "<Nop>", {
  silent = true,
  desc = "Reserve Space as leader prefix",
}) -- Prevent bare Space from performing an unrelated action while it acts as leader.


-- ============================================================================
-- SAFE BUFFER CLOSING
-- ============================================================================

local function find_replacement_buffer(current_buf)
  local alternate = vim.fn.bufnr("#") -- Prefer the alternate buffer because it usually matches recent workflow.

  if
    alternate > 0
    and alternate ~= current_buf
    and api.nvim_buf_is_valid(alternate)
    and vim.bo[alternate].buflisted
  then
    return alternate
  end

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if
      buf ~= current_buf
      and api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
    then
      return buf -- Fall back to another listed buffer if no useful alternate buffer exists.
    end
  end

  return nil -- No existing listed buffer is available as a replacement.
end

local function close_current_buffer()
  local current_buf = api.nvim_get_current_buf()
  local force_delete = false

  if vim.bo[current_buf].modified then
    local choice = vim.fn.confirm(
      "Save changes before closing this buffer?",
      "&Save\n&Discard\n&Cancel",
      3
    ) -- Protect unsaved work instead of silently discarding it.

    if choice == 1 then
      local ok, err = pcall(vim.cmd, "write") -- Save the current buffer before closing it.

      if not ok then
        vim.notify(
          "Could not save buffer: " .. tostring(err),
          vim.log.levels.ERROR
        ) -- Leave the buffer open when writing fails.
        return
      end
    elseif choice == 2 then
      force_delete = true -- Explicit Discard permits deleting an unsaved buffer.
    else
      return -- Cancel/Escape leaves the current buffer and window untouched.
    end
  end

  local replacement = find_replacement_buffer(current_buf)

  if replacement then
    api.nvim_set_current_buf(replacement) -- Reuse the current window instead of closing the split.
  else
    local new_buf = api.nvim_create_buf(true, false)
    api.nvim_set_current_buf(new_buf) -- Keep the window alive with a fresh empty buffer when necessary.
  end

  local ok, err = pcall(api.nvim_buf_delete, current_buf, {
    force = force_delete,
  }) -- Delete only the old buffer after the current window has a replacement.

  if not ok then
    if api.nvim_buf_is_valid(current_buf) then
      api.nvim_set_current_buf(current_buf)
    end

    vim.notify(
      "Could not close buffer: " .. tostring(err),
      vim.log.levels.ERROR
    ) -- Restore the original buffer when deletion unexpectedly fails.
  end
end


-- ============================================================================
-- GENERAL LEADER ACTIONS
-- ============================================================================

map("n", "<leader>w", "<cmd>write<cr>", {
  silent = true,
  desc = "Save buffer",
}) -- Save the current buffer to disk.

map("n", "<leader>q", "<cmd>quit<cr>", {
  silent = true,
  desc = "Quit window",
}) -- Quit the current window; 'confirm' protects unsaved changes.

map("n", "<leader>c", close_current_buffer, {
  silent = true,
  desc = "Close buffer safely",
}) -- Close the current buffer while preserving the window/layout where practical.

map("n", "<leader>h", "<cmd>nohlsearch<cr>", {
  silent = true,
  desc = "Clear search highlights",
}) -- Hide the current search highlights without deleting the search pattern.


-- ============================================================================
-- WINDOW NAVIGATION
-- ============================================================================

map("n", "<C-h>", "<C-w>h", {
  silent = true,
  desc = "Focus left split",
}) -- Move focus to the Neovim window on the left.

map("n", "<C-j>", "<C-w>j", {
  silent = true,
  desc = "Focus lower split",
}) -- Move focus to the Neovim window below.

map("n", "<C-k>", "<C-w>k", {
  silent = true,
  desc = "Focus upper split",
}) -- Move focus to the Neovim window above.

map("n", "<C-l>", "<C-w>l", {
  silent = true,
  desc = "Focus right split",
}) -- Move focus to the Neovim window on the right.


-- ============================================================================
-- WINDOW RESIZING
-- ============================================================================

map("n", "<C-Up>", "<cmd>resize +2<cr>", {
  silent = true,
  desc = "Increase split height",
}) -- Make the current horizontal split two rows taller.

map("n", "<C-Down>", "<cmd>resize -2<cr>", {
  silent = true,
  desc = "Decrease split height",
}) -- Make the current horizontal split two rows shorter.

map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", {
  silent = true,
  desc = "Decrease split width",
}) -- Make the current vertical split two columns narrower.

map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", {
  silent = true,
  desc = "Increase split width",
}) -- Make the current vertical split two columns wider.


-- ============================================================================
-- BUFFER NAVIGATION
-- ============================================================================

map("n", "<S-h>", "<cmd>bprevious<cr>", {
  silent = true,
  desc = "Previous buffer",
}) -- Move to the previous buffer in the buffer list.

map("n", "<S-l>", "<cmd>bnext<cr>", {
  silent = true,
  desc = "Next buffer",
}) -- Move to the next buffer in the buffer list.


-- ============================================================================
-- MOVE CURRENT LINE
-- ============================================================================

map("n", "<A-j>", "<cmd>move .+1<cr>==", {
  silent = true,
  desc = "Move line down",
}) -- Move the current line down one row and re-indent it.

map("n", "<A-k>", "<cmd>move .-2<cr>==", {
  silent = true,
  desc = "Move line up",
}) -- Move the current line up one row and re-indent it.


-- ============================================================================
-- INSERT MODE
-- ============================================================================

map("i", "jj", "<Esc>", {
  silent = true,
  desc = "Exit insert mode",
}) -- Press jj quickly instead of reaching for Escape.

map("i", "<A-j>", "<Esc><cmd>move .+1<cr>==gi", {
  silent = true,
  desc = "Move line down",
}) -- Move the current line down and return to Insert mode.

map("i", "<A-k>", "<Esc><cmd>move .-2<cr>==gi", {
  silent = true,
  desc = "Move line up",
}) -- Move the current line up and return to Insert mode.


-- ============================================================================
-- VISUAL MODE
-- ============================================================================

map("x", "<", "<gv", {
  silent = true,
  desc = "Indent selection left",
}) -- Dedent selected text and immediately reselect it.

map("x", ">", ">gv", {
  silent = true,
  desc = "Indent selection right",
}) -- Indent selected text and immediately reselect it.

map("x", "<A-j>", ":move '>+1<cr>gv-gv", {
  silent = true,
  desc = "Move selection down",
}) -- Move the selected block down one line and preserve the selection.

map("x", "<A-k>", ":move '<-2<cr>gv-gv", {
  silent = true,
  desc = "Move selection up",
}) -- Move the selected block up one line and preserve the selection.

map("x", "J", ":move '>+1<cr>gv-gv", {
  silent = true,
  desc = "Move selection down",
}) -- Preserve the historical J shortcut for moving a visual selection downward.

map("x", "K", ":move '<-2<cr>gv-gv", {
  silent = true,
  desc = "Move selection up",
}) -- Preserve the historical K shortcut for moving a visual selection upward.

map("x", "p", '"_dP', {
  silent = true,
  desc = "Paste without replacing register",
}) -- Replace selected text without overwriting the value you originally yanked.


-- ============================================================================
-- TERMINAL MODE
-- ============================================================================

map("t", "<C-h>", "<C-\\><C-n><C-w>h", {
  silent = true,
  desc = "Focus left split",
}) -- Leave terminal input and move to the Neovim split on the left.

map("t", "<C-j>", "<C-\\><C-n><C-w>j", {
  silent = true,
  desc = "Focus lower split",
}) -- Leave terminal input and move to the Neovim split below.

map("t", "<C-k>", "<C-\\><C-n><C-w>k", {
  silent = true,
  desc = "Focus upper split",
}) -- Leave terminal input and move to the Neovim split above.

map("t", "<C-l>", "<C-\\><C-n><C-w>l", {
  silent = true,
  desc = "Focus right split",
}) -- Leave terminal input and move to the Neovim split on the right.


-- ============================================================================
-- COMMAND-LINE COMPLETION
-- ============================================================================

map("c", "<C-j>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<C-j>"
end, {
  expr = true,
  desc = "Next command-line completion",
}) -- Move downward through completion only when the command-line popup is visible.

map("c", "<C-k>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<C-k>"
end, {
  expr = true,
  desc = "Previous command-line completion",
}) -- Move upward through completion only when the command-line popup is visible.


-- ============================================================================
-- INTENTIONALLY NATIVE / DEFERRED MAPPINGS
-- ============================================================================
--
-- [q / ]q:
--   Neovim 0.12 already provides native previous/next quickfix mappings.
--
-- Insert-mode Alt+Arrow window navigation:
--   Intentionally omitted; Ctrl-h/j/k/l is our canonical window navigation.
--
-- Ctrl-q quickfix toggle:
--   Deferred until we design the quickfix UI rather than recreating old glue.
--
-- Plugin mappings:
--   Telescope, explorer, Git, terminal toggles, symbols, formatting, etc. are
--   added only when those features actually exist.
