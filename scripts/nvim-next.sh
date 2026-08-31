set -euo pipefail

worktree="${NVIM_NEXT_WORKTREE:-$HOME/projects/neovim-next}"

if [[ ! -d "$worktree" ]]; then
  echo "nvim-next: no active experiment exists." >&2
  echo >&2
  echo "Create one with:" >&2
  echo "  nvim-exp new <name>" >&2
  exit 1
fi

if [[ ! -f "$worktree/flake.nix" ]]; then
  echo "nvim-next: $worktree is not a valid Neovim worktree." >&2
  exit 1
fi

export NEOVIM_DEV_ROOT="$worktree"

exec nix develop "path:$worktree" \
  --command nvim-next-dev "$@"
