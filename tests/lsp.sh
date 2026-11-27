#!/usr/bin/env bash
set -euo pipefail

# Live protocol checks are separate from the short startup smoke probe.
nvim_bin="${NVIM_LSP_NVIM:-nvim}"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
export NVIM_LSP_TEST_ROOT="$test_root"
export HOME="$test_root/home"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_DATA_HOME="$test_root/data"
export XDG_STATE_HOME="$test_root/state"
export XDG_CACHE_HOME="$test_root/cache"
unset NVIM_COLORSCHEME VIRTUAL_ENV CONDA_PREFIX
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
# Test-only Python creates disposable environments, without pip or downloads.
"${NVIM_LSP_PYTHON:-python3}" - <<'PY'
import os, pathlib, venv
root = pathlib.Path(os.environ['NVIM_LSP_TEST_ROOT'])
for name in ('project/.venv', 'active-env'):
    env = root / name
    venv.EnvBuilder(with_pip=False).create(env)
    site = next(env.glob('lib/python*/site-packages'))
    (site / 'stage10_environment.py').write_text('environment_value: int = 123\n')
PY
probe_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$nvim_bin" --headless -c "lua dofile([[$probe_dir/lsp.lua]])"

# Startup-only checks use fresh processes and the same isolated HOME/XDG paths.
export NVIM_LSP_STARTUP_PROBE="$test_root/startup.lua"
cat > "$NVIM_LSP_STARTUP_PROBE" <<'LUA'
vim.schedule(function()
  local ok, err = xpcall(function()
    if vim.env.NVIM_LSP_TEST_MODE == "project" then
      assert(vim.g.stage10_project_override, "trusted exrc did not load")
      assert(vim.wait(20000, function()
        return #vim.lsp.get_clients({ bufnr = 0, name = "basedpyright" }) == 1
      end, 50), "project client did not attach")
      local client = vim.lsp.get_clients({ bufnr = 0, name = "basedpyright" })[1]
      assert(client.config.settings.python.pythonPath == vim.env.NVIM_LSP_TEST_ROOT .. "/active-env/bin/python",
        "trusted interpreter override lost")
      assert(client.settings.basedpyright.analysis.diagnosticMode == "workspace", "trusted server settings lost")
      print("neovim-lsp: trusted project overrides OK")
    else
      assert(not vim.lsp.is_enabled("marksman"), "unavailable server enabled")
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Still editable" })
      vim.bo.filetype = "markdown"
      require("aerial").sync_load()
      assert(vim.wait(2000, function() return vim.b.aerial_backend == "treesitter" end, 20),
        "missing server broke Treesitter fallback")
      assert(vim.v.errmsg == "", vim.v.errmsg)
      print("neovim-lsp: missing executable remains editable with fallback OK")
    end
  end, debug.traceback)
  if not ok then
    print(err)
    vim.cmd("cquit 1")
  else
    vim.cmd("qall!")
  end
end)
LUA

# The generated .nvim.lua was trusted by the first process, in this temporary HOME.
(
  cd "$test_root/project"
  export NVIM_LSP_TEST_MODE=project
  "$nvim_bin" --headless sample.py '+lua dofile(vim.env.NVIM_LSP_STARTUP_PROBE)'
)

# Simulate one missing executable at startup while retaining all other packages.
NVIM_LSP_TEST_MODE=unavailable "$nvim_bin" --headless \
  --cmd 'lua local executable=vim.fn.executable; vim.fn.executable=function(cmd) return cmd=="marksman" and 0 or executable(cmd) end' \
  '+lua dofile(vim.env.NVIM_LSP_STARTUP_PROBE)'
