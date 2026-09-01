local opt = vim.opt

-- ============================================================================
-- UI AND EDITOR FEEDBACK
-- ============================================================================

opt.number = true                    -- Show the current line number.
opt.relativenumber = true            -- Show relative numbers around the cursor for fast motions.
opt.numberwidth = 2                  -- Keep the number column compact.
opt.cursorline = true                -- Highlight the line containing the cursor.
opt.signcolumn = "yes"               -- Always reserve the sign column so diagnostics/Git never shift text.
opt.cmdheight = 1                    -- Keep one command/message line at the bottom.
opt.showmode = true                  -- Show -- INSERT -- / -- VISUAL -- until the future statusline replaces it.
opt.termguicolors = true             -- Enable full terminal RGB colors for the future colorscheme.
opt.list = false                     -- Keep whitespace markers hidden by default to reduce visual noise.
opt.conceallevel = 0                 -- Keep source markup such as Markdown backticks visibly editable.

opt.guicursor = {
  "n-v-c:block",                     -- Normal/Visual/Command modes use a block cursor.
  "i-ci-ve:ver25",                   -- Insert-like modes use a thin vertical cursor.
  "r-cr:hor20",                      -- Replace modes use a short horizontal cursor.
  "o:hor50",                         -- Operator-pending mode uses a half-height horizontal cursor.
}

-- The native tabline is intentionally NOT forced here.
-- Stage 8 will implement the browser-like buffer bar we actually want.


-- ============================================================================
-- INDENTATION FALLBACKS
-- ============================================================================
--
-- These are global fallback values only.
-- Filetype settings, .editorconfig, and project tooling may override them later.

opt.expandtab = true                 -- Insert spaces instead of literal tab characters.
opt.tabstop = 2                      -- Display a literal tab as two columns by default.
opt.shiftwidth = 2                   -- Use two spaces for each indentation level.
opt.softtabstop = 2                  -- Make <Tab>/<BS> behave like two-space indentation while editing.
opt.autoindent = true                -- Copy the previous line's indentation onto a new line.
opt.smartindent = true               -- Add simple syntax-aware indentation where Neovim can infer it.


-- ============================================================================
-- SEARCH
-- ============================================================================

opt.hlsearch = true                  -- Highlight all matches from the most recent search.
opt.ignorecase = true                -- Search case-insensitively when the pattern is all lowercase.
opt.smartcase = true                 -- Make search case-sensitive when the pattern contains uppercase letters.


-- ============================================================================
-- FILE AND EDITING BEHAVIOR
-- ============================================================================

opt.mouse = "a"                      -- Allow mouse selection, scrolling, resizing, and window interaction.
opt.clipboard = "unnamedplus"        -- Use the system clipboard for normal yank/delete/paste operations.

opt.swapfile = false                 -- Do not create Vim swap/recovery files beside active edits.
opt.backup = false                   -- Do not retain permanent backup copies after writing files.
opt.writebackup = false              -- Do not create temporary write-backup copies before overwriting files.
opt.undofile = false                 -- Keep undo history in memory only; do not persist it across restarts.

opt.confirm = true                   -- Ask what to do instead of failing when unsaved changes block an operation.
opt.wrap = false                     -- Keep long source lines on one screen line instead of wrapping visually.
opt.scrolloff = 12                   -- Keep twelve context lines visible above and below the cursor.
opt.sidescrolloff = 8                -- Keep eight context columns visible beside the cursor when scrolling sideways.
opt.virtualedit = "block"            -- Allow rectangular Visual Block selections beyond physical line endings.

opt.inccommand = "split"             -- Preview :substitute changes live in a temporary split before applying them.


-- ============================================================================
-- COMPLETION AND RESPONSIVENESS
-- ============================================================================

opt.completeopt = { "menuone", "noselect" } -- Show completion even for one result without preselecting an item.
opt.pumheight = 10                   -- Limit completion-style popup menus to ten visible entries.
opt.timeoutlen = 800                 -- Wait up to 800 ms for a multi-key mapping to finish.
opt.updatetime = 300                 -- Trigger CursorHold/update-driven behavior after 300 ms of inactivity.

opt.shortmess:append("c")            -- Suppress redundant completion-menu messages in the command area.


-- ============================================================================
-- WINDOW PLACEMENT AND MOTION
-- ============================================================================

opt.splitbelow = true                -- Open horizontal splits below the current window.
opt.splitright = true                -- Open vertical splits to the right of the current window.

opt.whichwrap:append("<,>,[,],h,l")  -- Allow left/right motions to cross line boundaries like the old LunarVim setup.


-- ============================================================================
-- SPELLING
-- ============================================================================

opt.spelllang = "en_us"              -- Use US English when spell checking is enabled.
opt.spell = false                    -- Keep spell checking off globally; writing filetypes can enable it later.


-- ============================================================================
-- PROJECT-LOCAL CONFIGURATION
-- ============================================================================

opt.exrc = true                      -- Load trusted project .nvim.lua/.nvimrc files discovered by Neovim.


-- ============================================================================
-- INTENTIONAL OMISSIONS
-- ============================================================================
--
-- shell:
--   Do not hard-code a shell for example: Fish. Neovim inherits the user's environment instead.
--
-- fileencoding:
--   Modern Neovim already uses UTF-8 internally; no global override is needed.
--
-- showtabline:
--   Do not build the future buffer workflow around native tabpages.
--
-- iskeyword+=-:
--   Keep normal Neovim word semantics; hyphens remain word separators.
--
-- loaded_netrw / loaded_netrwPlugin:
--   Keep the built-in filesystem fallback available until a real explorer exists.
--
-- listchars:
--   Whitespace visualization is off for now; a discoverable toggle can be added later.
