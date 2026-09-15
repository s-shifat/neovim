-- User configuration entry point.
-- Feature groups should be loaded from here as the configuration grows.

require("user.core") -- Load the plugin-free editor foundation.
require("user.ui")   -- Load the visual/plugin-aware editor layer.
require("user.navigation") -- Load search and navigation workflows.
