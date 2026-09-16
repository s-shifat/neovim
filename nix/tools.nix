{ pkgs }:

[
  pkgs.git # Required by Gitsigns for repository status and hunk operations.
  pkgs.ripgrep # Telescope grep backend; supplied to stable and experimental editors.
  pkgs.fd # Telescope file-discovery backend; supplied to stable and experimental editors.
  pkgs.imagemagick # Converts supported image and PDF files to PNG for Snacks.image.
  pkgs.ghostscript_headless # ImageMagick PDF delegate used by direct Snacks.image PDF viewing.
]
