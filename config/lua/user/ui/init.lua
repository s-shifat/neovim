local theme = require("user.ui.theme")
local catppuccin = require("user.ui.themes.catppuccin")
local icons = require("user.ui.icons")
local gitsigns = require("user.ui.gitsigns")
local statusline = require("user.ui.statusline")
local which_key = require("user.ui.which-key")


-- ============================================================================
-- THEME
-- ============================================================================

theme.setup({
  default = "catppuccin-mocha",

  configure = function(name)
    catppuccin.configure(name)
  end,
}) -- Use Mocha by default while delegating Catppuccin-specific behavior to its own module.


-- ============================================================================
-- ICONS
-- ============================================================================

icons.setup() -- Initialize the shared icon provider against the active theme.


-- ============================================================================
-- GIT SIGNS
-- ============================================================================

gitsigns.setup() -- Add Git state and hunk actions only to attached buffers.


-- ============================================================================
-- STATUSLINE
-- ============================================================================

statusline.setup() -- Replace native mode feedback only after Lualine initializes.


-- ============================================================================
-- MAPPING DISCOVERY
-- ============================================================================

which_key.setup() -- Discover the descriptions already attached to existing mappings.
