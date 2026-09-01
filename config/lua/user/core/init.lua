-- Core editor configuration.
-- Keep this layer plugin-free so basic editing never depends on optional tools.

require("user.core.options")   -- Load native Neovim options first.
require("user.core.keymaps")   -- Load global native keybindings second.
require("user.core.autocmds")  -- Load automatic editor behavior last.
