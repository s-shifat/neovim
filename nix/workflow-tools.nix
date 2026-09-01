{ pkgs }:

let
  nextLauncher = pkgs.writeShellApplication {
    name = "nvim-next";

    runtimeInputs = [
      pkgs.nix
    ];

    text = builtins.readFile ../scripts/nvim-next.sh;
  };

  experimentManager = pkgs.writeShellApplication {
    name = "nvim-exp";

    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.nix
      pkgs.openssh
      nextLauncher
    ];

    text = builtins.readFile ../scripts/nvim-exp.sh;
  };
in
pkgs.symlinkJoin {
  name = "neovim-workflow-tools";

  paths = [
    nextLauncher
    experimentManager
  ];
}
