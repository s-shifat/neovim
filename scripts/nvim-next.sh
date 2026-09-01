set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
repo_path_file="$config_home/nvim-exp/repo-path"

saved_repo=""
if [[ -f "$repo_path_file" ]]; then
  IFS= read -r saved_repo < "$repo_path_file" || true
fi

stable_repo="${NVIM_STABLE_REPO:-${saved_repo:-$HOME/projects/neovim}}"
worktree="${NVIM_NEXT_WORKTREE:-${stable_repo}-next}"

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
