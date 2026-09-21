local M = {}

local config = {
  default_amount = 3,
  float_win_behavior = "previous",
  disable_multiplexer_nav_when_zoomed = true,
  -- The pinned plugin tries the mux before stopping at the Neovim edge.
  at_edge = "stop",
  -- Integrate tmux only; do not auto-select Kitty outside tmux.
  multiplexer_integration = vim.env.TMUX and "tmux" or false,
}

-- Future capabilities (intentionally unmapped):
-- at_edge = "wrap" / "split": opposite Neovim edge / create a split.
-- move_cursor_previous(): previous split/pane where supported.
-- swap_buf_left(), swap_buf_down(), swap_buf_up(), swap_buf_right(): swap buffers.
-- cursor_follows_swapped_bufs: cursor behavior when swapping buffers.
-- move_cursor_same_row: preserve screen row during horizontal movement.
-- float_win_behavior = "mux": forward float navigation directly to the mux.
-- Persistent resize mode was removed upstream; do not design around it.

function M.setup()
  local ok, splits = pcall(require, "smart-splits")
  if not ok then
    vim.notify("smart-splits: unavailable: " .. tostring(splits), vim.log.levels.WARN)
    return
  end

  local configured, setup_error = pcall(splits.setup, config)
  if not configured then
    vim.notify("smart-splits: setup failed: " .. tostring(setup_error), vim.log.levels.WARN)
    return
  end

  -- Core mappings remain intact until plugin setup succeeds.
  for _, mapping in ipairs({
    { "h", "Left", "left" },
    { "j", "Down", "down" },
    { "k", "Up", "up" },
    { "l", "Right", "right" },
  }) do
    local key, arrow, direction = unpack(mapping)
    vim.keymap.set("n", "<C-" .. key .. ">", splits["move_cursor_" .. direction], {
      desc = "Navigate " .. direction .. " across splits and tmux panes",
    })
    vim.keymap.set(
      "t",
      "<C-" .. key .. ">",
      "<C-\\><C-n><cmd>lua require('smart-splits').move_cursor_" .. direction .. "()<cr>",
      {
        silent = true,
        desc = "Leave terminal input and navigate " .. direction,
      }
    )
    vim.keymap.set("n", "<C-" .. arrow .. ">", splits["resize_" .. direction], {
      desc = "Resize " .. direction .. " by 3",
    })
  end
end

return M
