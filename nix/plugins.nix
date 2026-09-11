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

    nvim-web-devicons # Filetype/filename icons using the Nerd Font provided by the host system.
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
