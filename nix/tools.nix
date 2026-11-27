{ pkgs }:

[
  pkgs.git # Required by Gitsigns for repository status and hunk operations.
  pkgs.ripgrep # Telescope grep backend; supplied to stable and experimental editors.
  pkgs.fd # Telescope file-discovery backend; supplied to stable and experimental editors.
  pkgs.imagemagick # Converts supported image and PDF files to PNG for Snacks.image.
  pkgs.ghostscript_headless # ImageMagick PDF delegate used by direct Snacks.image PDF viewing.

  # Language servers shared by packaged nvim and nvim-next.
  pkgs.lua-language-server
  pkgs.nixd
  pkgs.bash-language-server
  pkgs.basedpyright
  pkgs.vscode-langservers-extracted # JSON/JSONC; only jsonls is enabled.
  pkgs.yaml-language-server
  pkgs.taplo
  pkgs.marksman
  pkgs.texlab
]
