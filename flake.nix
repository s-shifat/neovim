{
  description = "Nix-managed Neovim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          nvim = import ./nix/package.nix {
            inherit pkgs;
            configDir = ./config;
          };
        in
        {
          inherit nvim;
          default = nvim;
        }
      );
    };
}
