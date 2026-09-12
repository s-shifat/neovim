local theme = require("user.ui.theme")
local catppuccin = require("user.ui.themes.catppuccin")
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
-- MAPPING DISCOVERY
-- ============================================================================

which_key.setup() -- Discover the descriptions already attached to existing mappings.
