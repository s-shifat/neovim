local M = {}


-- ============================================================================
-- MAPPING DISCOVERY
-- ============================================================================

function M.setup()
  local which_key = require("which-key")

  which_key.setup({
    delay = 300, -- Show available continuations after a brief leader-key pause.

    icons = {
      mappings = false, -- Keep mapping labels textual without icon dependencies.
    },
  })

  which_key.add({
    { "<leader>g", group = "Git" },
  })
end


return M
