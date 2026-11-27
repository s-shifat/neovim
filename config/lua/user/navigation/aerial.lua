local M = {}

local config = {
  -- Prefer server symbols; native parser queries remain the offline fallback.
  backends = { "lsp", "treesitter" },
  attach_mode = "global", -- Follow the active editing window across splits.
  open_automatic = false,
  layout = {
    default_direction = "right",
    placement = "edge", -- Keep Explorer on the opposite edge.
    min_width = 24,
    max_width = { 40, 0.25 },
  },
  filter_kind = false, -- Include document headings and other upstream query symbols.
  highlight_mode = "last",
  show_guides = true,
  -- Upstream owns outline-local jump/tree mappings and auto-detects devicons.
  -- Source-buffer motions and folding stay native.
}

function M.symbols()
  local available, aerial = pcall(require, "aerial")
  if not available then
    vim.notify("Document symbols: Aerial is unavailable", vim.log.levels.WARN)
    return
  end
  aerial.sync_load()
  -- The extension reports missing backends as errors; keep unsupported files quiet.
  if not require("aerial.backends").get() then
    vim.notify("No document symbol backend for this buffer", vim.log.levels.INFO)
    return
  end
  require("telescope").extensions.aerial.aerial()
end

function M.setup()
  local available, aerial = pcall(require, "aerial")
  local configured, setup_err = false, aerial
  if available then
    configured, setup_err = pcall(aerial.setup, config)
  end
  if not configured then
    vim.notify_once("Could not initialize Aerial: " .. tostring(setup_err), vim.log.levels.WARN)
    return
  end

  vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle<cr>", { desc = "Toggle symbol outline" })
end

return M
