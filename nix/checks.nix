{
  pkgs,
  nvim,
  workflowTools,
  configDir,
}:

{
  smoke = pkgs.runCommand "neovim-smoke-check"
    {
      nativeBuildInputs = [
        pkgs.bash
        pkgs.coreutils
        nvim
      ];
    }
    ''
      export NVIM_SMOKE_NVIM="${nvim}/bin/nvim"
      export NVIM_SMOKE_EXPECT_RUNTIME="${configDir}"

      bash ${../tests/smoke.sh}

      touch "$out"
    '';

  workflow-tools = workflowTools;
}
