#!/usr/bin/env bash

set -euo pipefail

stable_cmd="${NVIM_STABLE_CMD:-nvim}"
next_cmd="${NVIM_NEXT_CMD:-nvim-next}"

probe_with() {
  "$@" \
    --headless \
    '+lua print("NVIM_STATE_APPNAME=" .. (vim.env.NVIM_APPNAME or "<unset>"))' \
    '+lua print("NVIM_STATE_CONFIG=" .. vim.fn.stdpath("config"))' \
    '+lua print("NVIM_STATE_DATA=" .. vim.fn.stdpath("data"))' \
    '+lua print("NVIM_STATE_STATE=" .. vim.fn.stdpath("state"))' \
    '+lua print("NVIM_STATE_CACHE=" .. vim.fn.stdpath("cache"))' \
    '+lua local f=vim.o.shadafile; if f=="" then f=vim.fn.stdpath("state") .. "/shada/main.shada" end; print("NVIM_STATE_SHADA=" .. f)' \
    '+lua print("NVIM_STATE_UNDOFILE=" .. tostring(vim.o.undofile))' \
    '+lua print("NVIM_STATE_SESSION=" .. (vim.v.this_session ~= "" and vim.v.this_session or "<none>"))' \
    '+qall'
}

value_from() {
  local output="$1"
  local key="$2"

  printf '%s\n' "$output" \
    | sed -n "s/^NVIM_STATE_${key}=//p" \
    | tail -n 1
}

fail() {
  echo "state-isolation: FAIL: $*" >&2
  exit 1
}

echo "Probing stable Neovim..."

stable_output="$(
  probe_with env -u NVIM_APPNAME "$stable_cmd" 2>&1
)"

echo "Probing experimental Neovim..."

next_output="$(
  probe_with "$next_cmd" 2>&1
)"

stable_appname="$(value_from "$stable_output" APPNAME)"
next_appname="$(value_from "$next_output" APPNAME)"

stable_config="$(value_from "$stable_output" CONFIG)"
next_config="$(value_from "$next_output" CONFIG)"

stable_data="$(value_from "$stable_output" DATA)"
next_data="$(value_from "$next_output" DATA)"

stable_state="$(value_from "$stable_output" STATE)"
next_state="$(value_from "$next_output" STATE)"

stable_cache="$(value_from "$stable_output" CACHE)"
next_cache="$(value_from "$next_output" CACHE)"

stable_shada="$(value_from "$stable_output" SHADA)"
next_shada="$(value_from "$next_output" SHADA)"

stable_undofile="$(value_from "$stable_output" UNDOFILE)"
next_undofile="$(value_from "$next_output" UNDOFILE)"

stable_session="$(value_from "$stable_output" SESSION)"
next_session="$(value_from "$next_output" SESSION)"

[[ "$next_appname" == "nvim-next" ]] ||
  fail "experimental NVIM_APPNAME is '$next_appname', expected 'nvim-next'"

[[ "$stable_config" != "$next_config" ]] ||
  fail "config paths are shared"

[[ "$stable_data" != "$next_data" ]] ||
  fail "data paths are shared"

[[ "$stable_state" != "$next_state" ]] ||
  fail "state paths are shared"

[[ "$stable_cache" != "$next_cache" ]] ||
  fail "cache paths are shared"

[[ "$stable_shada" != "$next_shada" ]] ||
  fail "ShaDa paths are shared"

cat <<EOF

Stable
  appname:  $stable_appname
  config:   $stable_config
  data:     $stable_data
  state:    $stable_state
  cache:    $stable_cache
  shada:    $stable_shada
  undofile: $stable_undofile
  session:  $stable_session

Experimental
  appname:  $next_appname
  config:   $next_config
  data:     $next_data
  state:    $next_state
  cache:    $next_cache
  shada:    $next_shada
  undofile: $next_undofile
  session:  $next_session

state-isolation: PASS
EOF
