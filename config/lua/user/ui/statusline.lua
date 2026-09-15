local M = {}


-- ============================================================================
-- COMPONENTS
-- ============================================================================

local function lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  if #clients == 0 then
    return ""
  end

  return "LSP"
end

local function warn_once(message)
  vim.notify_once(
    message,
    vim.log.levels.WARN,
    { title = "Neovim statusline" }
  )
end


-- ============================================================================
-- STATUSLINE SETUP
-- ============================================================================

function M.setup()
  local available, lualine = pcall(require, "lualine")

  if not available then
    warn_once("Lualine is unavailable; using native mode feedback")
    return
  end

  local configured, setup_err = pcall(lualine.setup, {
    options = {
      theme = "auto",
      globalstatus = true,
    },

    sections = {
      lualine_a = { "mode" },

      lualine_b = {
        "branch",
        "diagnostics",
      },

      lualine_c = {
        {
          "filename",
          path = 1,
        },
      },

      lualine_x = {
        "filetype",
        lsp_status,
      },

      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  })

  if not configured then
    warn_once(
      "Could not initialize Lualine: " .. tostring(setup_err)
    )
    return
  end

  vim.o.showmode = false
end


return M
