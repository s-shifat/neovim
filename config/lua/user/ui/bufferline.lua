local M = {}
local buffers = require("user.core.buffers")

local config = {
  options = {
    mode = "buffers",
    always_show_bufferline = true,
    numbers = "none",
    show_buffer_icons = true,
    show_buffer_close_icons = true,
    show_close_icon = false,
    show_duplicate_prefix = true,
    modified_icon = "●",
    separator_style = "thin",
    max_name_length = 18,
    enforce_regular_tabs = false,
    sort_by = "id",
    diagnostics = false,
    show_tab_indicators = false,
    close_command = buffers.close,
    middle_mouse_command = buffers.close,
    left_mouse_command = "buffer %d",
    right_mouse_command = false,
  },
}

local function make_config()
  local result = vim.deepcopy(config)
  if (vim.g.colors_name or ""):match("^catppuccin") then
    result.highlights = require("catppuccin.special.bufferline").get_theme()
  end
  return result
end

-- Future capabilities (no additional mappings or inactive configuration):
-- diagnostics = "nvim_lsp": reconsider with Stage 10 LSP.
-- BufferLinePick / BufferLinePickClose: Telescope owns fuzzy buffer discovery.
-- BufferLineTogglePin and groups: only if pinning/grouping becomes useful.
-- BufferLineMovePrev / BufferLineMoveNext: manual reordering is deferred.
-- BufferLineCloseLeft / BufferLineCloseRight / BufferLineCloseOthers: first
-- design safe bulk-close semantics. custom_areas: currently unnecessary.
-- offsets: intentionally absent for Snacks Explorer; keep the bar full-width.
-- show_tab_indicators: disabled because this strip represents buffers.

function M.setup()
  local available, bufferline = pcall(require, "bufferline")
  local configured, setup_err = false, bufferline
  if available then
    configured, setup_err = pcall(function()
      bufferline.setup(make_config())
    end)
  end
  if not configured then
    vim.notify_once(
      "Could not initialize Bufferline; using native buffer navigation: " .. tostring(setup_err),
      vim.log.levels.WARN
    )
    return
  end

  -- Bufferline 4.9.1 ignores the mouse button on close icons. Consume right
  -- clicks on the bar as well as disabling its normal right-click command.
  vim.keymap.set({ "n", "x", "s", "o", "i", "c", "t" }, "<RightMouse>", function()
    return vim.fn.getmousepos().screenrow == 1 and "<Ignore>" or "<RightMouse>"
  end, { expr = true, desc = "Ignore right-click on buffer bar" })

  vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", {
    silent = true,
    desc = "Previous visible buffer",
  })
  vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", {
    silent = true,
    desc = "Next visible buffer",
  })
end

return M
