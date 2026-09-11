local theme = require("user.ui.theme")
local catppuccin = require("user.ui.themes.catppuccin")


-- ============================================================================
-- THEME
-- ============================================================================

theme.setup({
  default = "catppuccin-mocha",

  configure = function(name)
    catppuccin.configure(name)
  end,
}) -- Use Mocha by default while delegating Catppuccin-specific behavior to its own module.
