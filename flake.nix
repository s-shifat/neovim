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

          workflowTools = import ./nix/workflow-tools.nix {
            inherit pkgs;
          };

          full = pkgs.symlinkJoin {
            name = "neovim-full";

            paths = [
              nvim
              workflowTools
            ];

            meta.mainProgram = "nvim";
          };
        in
        {
          inherit nvim full;

          workflow-tools = workflowTools;

          default = nvim;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          nvim = import ./nix/package.nix {
            inherit pkgs;
            configDir = ./config;
          };

          workflowTools = import ./nix/workflow-tools.nix {
            inherit pkgs;
          };
        in
        import ./nix/checks.nix {
          inherit
            pkgs
            nvim
            workflowTools
            ;

          configDir = ./config;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = import ./nix/dev-shell.nix {
            inherit pkgs;
          };
        }
      );
    };
}
