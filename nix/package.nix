{ pkgs, configDir }:

let
  plugins = import ./plugins.nix {
    inherit pkgs;
  };
in
pkgs.neovim.override {
  configure = {
    # Use the same Nix-owned plugin inventory as the experimental editor.
    packages.user = plugins;

    # Load the immutable packaged Lua configuration.
    customRC = ''
      set runtimepath^=${configDir}
      lua dofile("${configDir}/init.lua")
    '';
  };
}
