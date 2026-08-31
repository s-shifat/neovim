{ pkgs, configDir }:

pkgs.neovim.override {
  configure = {
    customRC = ''
      set runtimepath^=${configDir}
      lua dofile("${configDir}/init.lua")
    '';
  };
}
