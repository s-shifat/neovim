{ pkgs }:

[
  pkgs.git # Required by Gitsigns for repository status and hunk operations.
  pkgs.ripgrep # Telescope grep backend; supplied to stable and experimental editors.
  pkgs.fd # Telescope file-discovery backend; supplied to stable and experimental editors.
]
