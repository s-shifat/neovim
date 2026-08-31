{ pkgs }:

let
  nvimNextDev = pkgs.writeShellApplication {
    name = "nvim-next-dev";

    runtimeInputs = [
      pkgs.neovim
    ];

    text = ''
      if [[ -z "''${NEOVIM_DEV_ROOT:-}" ]]; then
        echo "nvim-next-dev: NEOVIM_DEV_ROOT is not set." >&2
        exit 1
      fi

      export NVIM_APPNAME=nvim-next

      exec nvim \
        -u "$NEOVIM_DEV_ROOT/dev/init.lua" \
        "$@"
    '';
  };
in
pkgs.mkShell {
  packages = [
    pkgs.neovim
    nvimNextDev
  ];
}
