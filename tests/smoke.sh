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

# Test the editor's declared default theme, not a caller-provided temporary override.
unset NVIM_COLORSCHEME

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

-- Verify that the Nix-packaged theme plugin and declared default colorscheme loaded.
local catppuccin_ok, catppuccin_err = pcall(require, "catppuccin")

if not catppuccin_ok then
  fail(
    "Catppuccin plugin is unavailable: "
      .. tostring(catppuccin_err)
  )
end

local theme_default = vim.g.neovim_theme_default
local theme_requested = vim.g.neovim_theme_requested
local theme_loaded = vim.g.neovim_theme_loaded

if type(theme_default) ~= "string" or theme_default == "" then
  fail("default colorscheme was not declared")
end

if theme_requested ~= theme_default then
  fail(
    ("startup requested colorscheme '%s', expected default '%s'")
      :format(
        tostring(theme_requested),
        tostring(theme_default)
      )
  )
end

if theme_loaded ~= theme_requested then
  fail(
    ("requested colorscheme '%s' but loaded '%s'")
      :format(
        tostring(theme_requested),
        tostring(theme_loaded)
      )
  )
end

if vim.g.colors_name ~= theme_loaded then
  fail(
    ("Neovim reports active colorscheme '%s', expected '%s'")
      :format(
        tostring(vim.g.colors_name),
        tostring(theme_loaded)
      )
  )
end

-- Verify that the shared icon provider was initialized during normal UI startup.
local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

if not devicons_ok then
  fail("nvim-web-devicons plugin is unavailable")
end

if devicons.has_loaded() ~= true then
  fail("nvim-web-devicons was not initialized during UI startup")
end

-- Verify that the packaged statusline initialized and replaced native mode text.
if package.loaded.lualine == nil then
  fail("Lualine was not initialized during UI startup")
end

if vim.o.showmode then
  fail("native showmode remained enabled after Lualine initialized")
end

if vim.o.laststatus ~= 3 then
  fail("Lualine did not configure one global statusline")
end

-- Verify that the packaged Git-sign layer is available and initialized.
local gitsigns_ok, gitsigns_err = pcall(require, "gitsigns")

if not gitsigns_ok then
  fail("Gitsigns plugin is unavailable: " .. tostring(gitsigns_err))
end

if package.loaded.gitsigns == nil then
  fail("Gitsigns was not initialized during UI startup")
end

if vim.fn.executable("git") ~= 1 then
  fail("Git is unavailable to the packaged editor")
end

-- Verify that Snacks owns the standard notification route and only its notifier
-- lifecycle was enabled during normal UI startup.
local snacks_ok, snacks = pcall(require, "snacks")

if not snacks_ok then
  fail("Snacks plugin is unavailable")
end

if snacks.did_setup ~= true then
  fail("Snacks was not initialized during UI startup")
end

if snacks.config.notifier.enabled ~= true then
  fail("Snacks notifier is not enabled")
end

vim.notify("notification smoke test", vim.log.levels.INFO)

if vim.notify ~= snacks.notifier.notify then
  fail("vim.notify was not routed through Snacks notifier")
end

for _, module in ipairs({
  "bigfile",
  "dashboard",
  "explorer",
  "indent",
  "input",
  "picker",
  "quickfile",
  "scope",
  "scroll",
  "statuscolumn",
  "words",
}) do
  if snacks.config[module].enabled ~= false then
    fail("unexpected Snacks module enabled: " .. module)
  end
end

-- Exercise core TextYankPost behavior so broken autocmd callbacks fail the smoke test.
local yank_ok, yank_err = pcall(function()
  vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    {
      "smoke yank line one",
      "smoke yank line two",
    }
  )

  vim.cmd("normal! gg")
  vim.cmd("normal! yy") -- Trigger TextYankPost for a real yank.
  vim.cmd("normal! dd") -- Trigger TextYankPost for a real delete.
end)

if not yank_ok then
  fail("TextYankPost callback failed: " .. tostring(yank_err))
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
