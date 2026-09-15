local M = {}

local configured = false


-- ============================================================================
-- THEME IDENTIFICATION
-- ============================================================================

local function is_catppuccin(name)
  return name == "catppuccin"
    or vim.startswith(name, "catppuccin-")
end


-- ============================================================================
-- CATPPUCCIN CONFIGURATION
-- ============================================================================

function M.configure(name)
  if not is_catppuccin(name) then
    return -- Ignore colorschemes owned by other theme plugins.
  end

  if configured then
    return -- Catppuccin only needs to be configured once per Neovim session.
  end

  local ok, catppuccin = pcall(require, "catppuccin")

  if not ok then
    error(
      "Catppuccin is not available even though a Catppuccin colorscheme was requested"
    )
  end

  catppuccin.setup({
    -- ------------------------------------------------------------------------
    -- BACKGROUND AND TERMINAL COLORS
    -- ------------------------------------------------------------------------

    transparent_background = false, -- Keep normal editor windows fully opaque.

    float = {
      transparent = false, -- Keep floating windows opaque as well.
    },

    term_colors = false, -- Do not replace the terminal's ANSI color palette.


    -- ------------------------------------------------------------------------
    -- INACTIVE WINDOWS
    -- ------------------------------------------------------------------------

    dim_inactive = {
      enabled = false, -- Keep inactive splits at normal brightness.
    },


    -- ------------------------------------------------------------------------
    -- TEXT STYLING
    -- ------------------------------------------------------------------------

    no_italic = false, -- Allow Catppuccin to use italic highlight styles.
    no_bold = false, -- Allow Catppuccin to use bold highlight styles.
    no_underline = false, -- Allow Catppuccin to use underline highlight styles.

    styles = {
      comments = { "italic" }, -- Display comments in italics like the historical setup.
      conditionals = { "italic" }, -- Display conditionals in italics like the historical setup.
    },


    -- ------------------------------------------------------------------------
    -- PLUGIN INTEGRATIONS
    -- ------------------------------------------------------------------------

    auto_integrations = false, -- Never silently enable integrations based on detected plugins.

    integrations = {
      gitsigns = true, -- Use Catppuccin highlights for Git gutter signs.
      which_key = true, -- Apply Catppuccin highlights to the Which-Key popup.
    },
  })

  configured = true
end


return M
