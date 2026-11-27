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
        pkgs.git
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

  # Real server handshakes and environment resolution need their own bounded
  # integration check; startup smoke remains fast and installer-free.
  lsp = pkgs.runCommand "neovim-lsp-check"
    {
      nativeBuildInputs = [ pkgs.bash pkgs.coreutils pkgs.python3 nvim ];
    }
    ''
      export NVIM_LSP_NVIM="${nvim}/bin/nvim"
      bash ${../tests}/lsp.sh
      touch "$out"
    '';
}
