{ pkgs, configDir }:

let
  plugins = import ./plugins.nix {
    inherit pkgs;
  };

  tools = import ./tools.nix {
    inherit pkgs;
  };

  nvim = pkgs.neovim.override {
    configure = {
      # Use the same Nix-owned plugin inventory as the experimental editor.
      packages.user = plugins;

      # Load the immutable packaged Lua configuration.
      customRC = ''
        set runtimepath^=${configDir}
        lua dofile("${configDir}/init.lua")
      '';
    };
  };
in
pkgs.symlinkJoin {
  name = "neovim-with-tools";

  paths = [ nvim ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    wrapProgram "$out/bin/nvim" \
      --prefix PATH : ${pkgs.lib.makeBinPath tools}
  '';

  meta.mainProgram = "nvim";
}
