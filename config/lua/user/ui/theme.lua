local api = vim.api

local M = {}


-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

local function load_colorscheme(name, configure)
  if configure then
    local configured, configure_err = pcall(configure, name)

    if not configured then
      return false, "configuration failed: " .. tostring(configure_err)
    end
  end

  local loaded, load_err = pcall(vim.cmd.colorscheme, name)

  if not loaded then
    return false, tostring(load_err)
  end

  return true
end

local function warn_once(message)
  vim.notify_once(
    message,
    vim.log.levels.WARN,
    { title = "Neovim theme" }
  ) -- Report theme problems once without making editor startup fatal.
end


-- ============================================================================
-- THEME SETUP
-- ============================================================================

function M.setup(opts)
  opts = opts or {}

  local default = assert(
    opts.default,
    "user.ui.theme: setup() requires a default colorscheme"
  )

  local override = vim.env.NVIM_COLORSCHEME

  if override == "" then
    override = nil -- Treat an empty environment variable as no override.
  end

  local requested = override or default

  vim.g.neovim_theme_default = default
  vim.g.neovim_theme_requested = requested
  vim.g.neovim_theme_loaded = nil


  -- ==========================================================================
  -- ACTIVE THEME TRACKING
  -- ==========================================================================

  local theme_state_group = api.nvim_create_augroup(
    "UserThemeState",
    { clear = true }
  )

  api.nvim_create_autocmd("ColorScheme", {
    group = theme_state_group,
    desc = "Track the active colorscheme",
    callback = function(event)
      vim.g.neovim_theme_loaded = event.match
    end,
  }) -- Keep our state accurate even after a manual :colorscheme command.


  -- ==========================================================================
  -- REQUESTED THEME
  -- ==========================================================================

  local loaded, load_err = load_colorscheme(
    requested,
    opts.configure
  )

  if loaded then
    return
  end


  -- ==========================================================================
  -- FALLBACK TO DEFAULT
  -- ==========================================================================

  if requested ~= default then
    warn_once(
      ("Could not load colorscheme '%s': %s. Falling back to '%s'.")
        :format(requested, load_err, default)
    )

    local fallback_loaded, fallback_err = load_colorscheme(
      default,
      opts.configure
    )

    if fallback_loaded then
      return
    end

    warn_once(
      ("Could not load default colorscheme '%s': %s. "
        .. "Continuing with Neovim's current colors.")
        :format(default, fallback_err)
    )

    return
  end


  -- ==========================================================================
  -- DEFAULT THEME FAILURE
  -- ==========================================================================

  warn_once(
    ("Could not load default colorscheme '%s': %s. "
      .. "Continuing with Neovim's current colors.")
      :format(default, load_err)
  )
end


return M
