#!/usr/bin/env bash

set -euo pipefail

nvim_bin="${NVIM_SMOKE_NVIM:-nvim}"
expected_runtime="${NVIM_SMOKE_EXPECT_RUNTIME:-}"

fail() {
  echo "neovim-smoke: FAIL: $*" >&2
  exit 1
}

if [[ "$nvim_bin" == */* ]]; then
  [[ -x "$nvim_bin" ]] ||
    fail "Neovim executable does not exist: $nvim_bin"
else
  command -v "$nvim_bin" >/dev/null 2>&1 ||
    fail "Neovim executable is not available: $nvim_bin"
fi

tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup EXIT

export HOME="$tmp_dir/home"
export XDG_CONFIG_HOME="$tmp_dir/xdg-config"
export XDG_DATA_HOME="$tmp_dir/xdg-data"
export XDG_STATE_HOME="$tmp_dir/xdg-state"
export XDG_CACHE_HOME="$tmp_dir/xdg-cache"

mkdir -p \
  "$HOME" \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$XDG_CACHE_HOME"

probe="$tmp_dir/probe.lua"
sentinel="$tmp_dir/smoke-ok"

export NVIM_SMOKE_SENTINEL="$sentinel"

cat > "$probe" <<'LUA'
local function fail(message)
  vim.api.nvim_err_writeln("neovim-smoke: FAIL: " .. message)
  vim.cmd("cquit 1")
end

if vim.g.neovim_config_loaded ~= true then
  fail("packaged Neovim configuration did not finish loading")
end

local expected_runtime = vim.env.NVIM_SMOKE_EXPECT_RUNTIME

if expected_runtime and expected_runtime ~= "" then
  local found = false

  for _, path in ipairs(vim.opt.runtimepath:get()) do
    if path == expected_runtime then
      found = true
      break
    end
  end

  if not found then
    fail(
      "expected configuration runtime is missing: "
        .. expected_runtime
    )
  end
end

local sentinel_path = vim.env.NVIM_SMOKE_SENTINEL

if not sentinel_path or sentinel_path == "" then
  fail("NVIM_SMOKE_SENTINEL is not set")
end

local result = vim.fn.writefile({ "ok" }, sentinel_path)

if result ~= 0 then
  fail("could not write smoke-test sentinel")
end

vim.cmd("qall")
LUA

output=""

if ! output="$(
  "$nvim_bin" \
    --headless \
    -c "luafile $probe" \
    2>&1
)"; then
  printf '%s\n' "$output" >&2
  fail "Neovim exited unsuccessfully"
fi

[[ -f "$sentinel" ]] ||
  fail "Neovim exited without completing the smoke probe"

echo "neovim-smoke: PASS"
