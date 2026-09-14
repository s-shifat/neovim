local M = {}


-- ============================================================================
-- ICON SETUP
-- ============================================================================

function M.setup()
  local ok, devicons = pcall(require, "nvim-web-devicons")

  if not ok then
    vim.notify_once(
      "nvim-web-devicons is unavailable",
      vim.log.levels.WARN
    )
    return
  end

  devicons.setup()
end


return M
