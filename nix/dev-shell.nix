{ pkgs }:

let
  # Use the exact same plugin inventory as packaged production Neovim.
  plugins = import ./plugins.nix {
    inherit pkgs;
  };

  tools = import ./tools.nix {
    inherit pkgs;
  };

  # Experimental Neovim contains the same Nix-owned plugins as production,
  # but does NOT embed the production Lua config. dev/init.lua loads the
  # experiment worktree's Lua configuration live instead.
  nvimDev = pkgs.neovim.override {
    configure = {
      packages.user = plugins;
    };
  };

  nvimNextDev = pkgs.writeShellApplication {
    name = "nvim-next-dev";

    runtimeInputs = [ nvimDev ] ++ tools;

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
    nvimDev
    nvimNextDev
  ] ++ tools;
}
