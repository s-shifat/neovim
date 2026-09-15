{ pkgs }:

{
  # ==========================================================================
  # START PLUGINS
  # ==========================================================================
  #
  # These plugins are available immediately when Neovim starts.
  # Nix owns installation/versioning; Lua only configures their behavior.

  start = with pkgs.vimPlugins; [
    # ------------------------------------------------------------------------
    # UI — THEMES
    # ------------------------------------------------------------------------

    catppuccin-nvim # Catppuccin colorscheme; Mocha will become our default.

    # ------------------------------------------------------------------------
    # UI — ICONS
    # ------------------------------------------------------------------------

    nvim-web-devicons # Shared icon provider for plugin-backed UI consumers.

    # ------------------------------------------------------------------------
    # UI — STATUSLINE
    # ------------------------------------------------------------------------

    lualine-nvim # Restrained global editor statusline.

    # ------------------------------------------------------------------------
    # UI — DISCOVERABILITY
    # ------------------------------------------------------------------------

    which-key-nvim # Discover existing described mappings after a short pause.

    # ------------------------------------------------------------------------
    # NAVIGATION — TELESCOPE
    # ------------------------------------------------------------------------

    plenary-nvim # Lua utility dependency used by Telescope.
    telescope-nvim # Primary fuzzy-search and discovery interface.
    telescope-fzf-native-nvim # Native fuzzy sorter for responsive large pickers.
    telescope-ui-select-nvim # Route vim.ui.select through Telescope.
    telescope-live-grep-args-nvim # Interactive ripgrep arguments for advanced search.

    # ------------------------------------------------------------------------
    # UI — NOTIFICATIONS
    # ------------------------------------------------------------------------

    snacks-nvim # Framework present for its notifier only in Stage 7E.

    # ------------------------------------------------------------------------
    # UI — GIT SIGNS
    # ------------------------------------------------------------------------

    gitsigns-nvim # Git gutter signs and buffer-local hunk actions.

  ];

  # ==========================================================================
  # OPTIONAL PLUGINS
  # ==========================================================================
  #
  # Keep this explicit even though it is empty today.
  # Future plugins that should require :packadd can live here without changing
  # the shape of the shared plugin inventory.

  opt = [ ];
}
