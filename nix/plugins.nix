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
    # UI — DISCOVERABILITY
    # ------------------------------------------------------------------------

    which-key-nvim # Discover existing described mappings after a short pause.

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
