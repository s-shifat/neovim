set -euo pipefail

default_repo_url="https://github.com/s-shifat/neovim.git"
default_stable_repo="$HOME/projects/neovim"
stable_branch="${NVIM_STABLE_BRANCH:-main}"

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_home/nvim-exp"
repo_path_file="$config_dir/repo-path"

saved_repo=""
if [[ -f "$repo_path_file" ]]; then
  IFS= read -r saved_repo < "$repo_path_file" || true
fi

stable_repo="${NVIM_STABLE_REPO:-${saved_repo:-$default_stable_repo}}"
next_worktree="${NVIM_NEXT_WORKTREE:-${stable_repo}-next}"

die() {
  echo "nvim-exp: $*" >&2
  exit 1
}

is_git_repo() {
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

is_neovim_repo() {
  local repo="$1"

  is_git_repo "$repo" &&
    [[ -f "$repo/flake.nix" ]] &&
    [[ -f "$repo/config/init.lua" ]] &&
    [[ -f "$repo/scripts/nvim-exp.sh" ]]
}

save_repo_path() {
  mkdir -p "$config_dir"
  printf '%s\n' "$stable_repo" > "$repo_path_file"
}

remote_url() {
  git -C "$1" remote get-url origin 2>/dev/null || printf 'none'
}

current_branch() {
  git -C "$1" branch --show-current
}

is_dirty() {
  [[ -n "$(git -C "$1" status --porcelain)" ]]
}

ensure_stable_repo() {
  is_neovim_repo "$stable_repo" || {
    echo "nvim-exp: no Neovim development repository is configured." >&2
    echo "Expected location: $stable_repo" >&2
    echo "Run: nvim-exp setup" >&2
    exit 1
  }
}

ensure_stable_branch_exists() {
  git -C "$stable_repo" show-ref \
    --verify \
    --quiet "refs/heads/$stable_branch" ||
    die "branch '$stable_branch' does not exist in $stable_repo"
}

ensure_next_worktree() {
  is_git_repo "$next_worktree" ||
    die "no active experiment worktree at $next_worktree"
}

ensure_stable_ready() {
  ensure_stable_repo
  ensure_stable_branch_exists

  local branch
  branch="$(current_branch "$stable_repo")"

  [[ "$branch" == "$stable_branch" ]] ||
    die "stable repository must be on '$stable_branch' (currently '$branch')"

  if is_dirty "$stable_repo"; then
    echo "Stable repository has uncommitted changes:" >&2
    git -C "$stable_repo" status --short >&2
    die "commit or discard them before continuing"
  fi
}

inside_next_worktree() {
  case "$PWD/" in
    "$next_worktree/"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

cmd_setup() {
  local input=""
  local clone_url="$default_repo_url"
  local clone_dir="$stable_repo"

  # Existing configured/default checkout: adopt it.
  if is_neovim_repo "$stable_repo"; then
    ensure_stable_branch_exists
    save_repo_path

    echo "Neovim development repository is ready."
    echo "  repository: $stable_repo"
    echo "  remote:     $(remote_url "$stable_repo")"
    echo "  branch:     $stable_branch"
    echo "  worktree:   $next_worktree"
    return 0
  fi

  [[ -t 0 ]] ||
    die "setup requires an interactive terminal when no development repository exists"

  echo "No local Neovim development repository was found."
  echo
  echo "A writable Git checkout is required only for experiments."
  echo "Stable 'nvim' works without it."
  echo

  printf 'Repository URL [%s]: ' "$default_repo_url"
  IFS= read -r input

  if [[ -n "$input" ]]; then
    clone_url="$input"
  fi

  printf 'Clone location [%s]: ' "$stable_repo"
  IFS= read -r input

  if [[ -n "$input" ]]; then
    case "$input" in
      \~)
        clone_dir="$HOME"
        ;;
      \~/*)
        clone_dir="$HOME/${input:2}"
        ;;
      *)
        clone_dir="$input"
        ;;
    esac
  fi

  stable_repo="$clone_dir"
  next_worktree="${NVIM_NEXT_WORKTREE:-${stable_repo}-next}"

  # If the user supplied a path that already contains the repository,
  # adopt it rather than cloning over it.
  if is_neovim_repo "$stable_repo"; then
    echo
    echo "Existing Neovim repository found:"
    echo "  repository: $stable_repo"
    echo "  remote:     $(remote_url "$stable_repo")"

    printf 'Use this repository for experiments? [Y/n] '
    IFS= read -r input

    case "$input" in
      n|N|no|NO)
        echo "Cancelled."
        return 0
        ;;
    esac

    ensure_stable_branch_exists
    save_repo_path

    echo
    echo "Experimental workflow configured."
    echo "  repository: $stable_repo"
    echo "  worktree:   $next_worktree"
    return 0
  fi

  # Never overwrite a non-empty unrelated directory.
  if [[ -e "$stable_repo" ]] &&
     [[ -n "$(ls -A "$stable_repo" 2>/dev/null || true)" ]]
  then
    die "clone location exists and is not the expected Neovim repository: $stable_repo"
  fi

  echo
  echo "Setup"
  echo "  repository: $clone_url"
  echo "  clone to:   $stable_repo"
  echo "  worktree:   $next_worktree"

  printf 'Continue? [Y/n] '
  IFS= read -r input

  case "$input" in
    n|N|no|NO)
      echo "Cancelled."
      return 0
      ;;
  esac

  mkdir -p "$(dirname "$stable_repo")"

  echo
  echo "Cloning development repository..."

  git clone "$clone_url" "$stable_repo"

  is_neovim_repo "$stable_repo" ||
    die "cloned repository does not have the expected Neovim repository structure"

  ensure_stable_branch_exists
  save_repo_path

  echo
  echo "Experimental workflow configured."
  echo "  repository: $stable_repo"
  echo "  remote:     $(remote_url "$stable_repo")"
  echo "  worktree:   $next_worktree"
}

ensure_or_offer_setup() {
  if is_neovim_repo "$stable_repo"; then
    return 0
  fi

  echo "No local Neovim development repository is configured."
  echo

  [[ -t 0 ]] ||
    die "run 'nvim-exp setup' from an interactive terminal"

  local answer=""

  printf 'Set it up now? [Y/n] '
  IFS= read -r answer

  case "$answer" in
    n|N|no|NO)
      echo "Cancelled."
      exit 0
      ;;
  esac

  echo
  cmd_setup

  if ! is_neovim_repo "$stable_repo"; then
    echo "Setup was not completed."
    exit 0
  fi
}

cmd_new() {
  local name="${1:-}"

  [[ -n "$name" ]] ||
    die "usage: nvim-exp new <name>"

  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] ||
    die "experiment name may contain only letters, numbers, '.', '_' and '-'"

  ensure_or_offer_setup
  ensure_stable_ready

  [[ ! -e "$next_worktree" ]] ||
    die "an experiment worktree already exists at $next_worktree"

  local branch="experiment/$name"

  if git -C "$stable_repo" show-ref \
    --verify \
    --quiet "refs/heads/$branch"
  then
    die "branch '$branch' already exists"
  fi

  echo "Creating experiment:"
  echo "  branch:   $branch"
  echo "  worktree: $next_worktree"
  echo

  git -C "$stable_repo" worktree add \
    -b "$branch" \
    "$next_worktree" \
    "$stable_branch"

  echo
  echo "Experiment created."
  echo "Launch it with:"
  echo "  nvim-next"
}

cmd_status() {
  echo "Development source"
  echo "  repo:       $stable_repo"

  if is_neovim_repo "$stable_repo"; then
    echo "  state:      ready"
    echo "  remote:     $(remote_url "$stable_repo")"
    echo "  branch:     $(current_branch "$stable_repo")"
    echo "  commit:     $(git -C "$stable_repo" rev-parse --short HEAD)"

    if is_dirty "$stable_repo"; then
      echo "  working:    modified"
    else
      echo "  working:    clean"
    fi
  else
    echo "  state:      not initialized"
    echo "  hint:       nvim-exp setup"
  fi

  echo
  echo "Experiment"

  if is_git_repo "$next_worktree"; then
    echo "  worktree:   $next_worktree"
    echo "  branch:     $(current_branch "$next_worktree")"
    echo "  commit:     $(git -C "$next_worktree" rev-parse --short HEAD)"

    if is_dirty "$next_worktree"; then
      echo "  working:    modified"
    else
      echo "  working:    clean"
    fi
  else
    echo "  active:     none"
    echo "  worktree:   $next_worktree"
  fi
}

cmd_discard() {
  ensure_stable_repo
  ensure_next_worktree

  if inside_next_worktree; then
    die "leave $next_worktree before discarding it"
  fi

  local branch
  branch="$(current_branch "$next_worktree")"

  [[ "$branch" == experiment/* ]] ||
    die "refusing to discard unexpected branch '$branch'"

  echo "Experiment to discard:"
  echo "  branch:   $branch"
  echo "  worktree: $next_worktree"
  echo

  git -C "$next_worktree" status --short
  echo

  local answer=""

  printf 'Discard this experiment permanently? [y/N] '
  IFS= read -r answer

  case "$answer" in
    y|Y|yes|YES)
      ;;
    *)
      echo "Cancelled."
      exit 0
      ;;
  esac

  git -C "$stable_repo" worktree remove \
    --force \
    "$next_worktree"

  git -C "$stable_repo" branch -D "$branch"
  git -C "$stable_repo" worktree prune

  echo
  echo "Experiment discarded."
}

cmd_promote() {
  ensure_stable_ready
  ensure_next_worktree

  if inside_next_worktree; then
    die "leave $next_worktree before promoting it"
  fi

  local branch
  branch="$(current_branch "$next_worktree")"

  [[ "$branch" == experiment/* ]] ||
    die "refusing to promote unexpected branch '$branch'"

  if is_dirty "$next_worktree"; then
    echo "Experiment has uncommitted changes:" >&2
    git -C "$next_worktree" status --short >&2
    die "commit the experiment before promotion"
  fi

  if ! git -C "$stable_repo" merge-base \
    --is-ancestor "$stable_branch" "$branch"
  then
    echo "Stable '$stable_branch' advanced after this experiment began." >&2
    echo "Rebase the experiment first:" >&2
    echo "  cd $next_worktree" >&2
    echo "  git rebase $stable_branch" >&2
    die "experiment is not based on current stable"
  fi

  echo "Building candidate before promotion..."

  nix build "path:$next_worktree#nvim" --no-link

  echo
  echo "Promoting:"
  echo "  $branch -> $stable_branch"
  echo

  git -C "$stable_repo" merge \
    --ff-only \
    "$branch"

  git -C "$stable_repo" worktree remove \
    "$next_worktree"

  git -C "$stable_repo" branch -d "$branch"
  git -C "$stable_repo" worktree prune

  echo
  echo "Source promotion complete."
  echo "Stable source is now:"

  git -C "$stable_repo" log -1 --oneline

  echo
  echo "Installed Neovim has NOT been changed automatically."
  echo "Deploy the new revision through your system configuration"
  echo "or upgrade the standalone Nix installation."
}

cmd_help() {
  cat <<'HELP'
Usage:
  nvim-exp setup
  nvim-exp new <name>
  nvim-exp status
  nvim-exp discard
  nvim-exp promote

Commands:
  setup     Configure or adopt the local development repository
  new       Create experiment/<name> in a temporary Git worktree
  status    Show development repository and experiment state
  discard   Permanently remove the active experiment
  promote   Build and fast-forward merge the experiment into main

Stable nvim does not require a local clone.

The checkout is required only for the experimental workflow.

On first use, setup asks for:
  - the Git repository URL
  - the local clone location

HTTPS and SSH URLs are both supported because Git handles the transport.

Environment overrides:
  NVIM_STABLE_REPO
  NVIM_NEXT_WORKTREE
  NVIM_STABLE_BRANCH
HELP
}

case "${1:-help}" in
  setup)
    cmd_setup
    ;;
  new)
    shift
    cmd_new "$@"
    ;;
  status)
    cmd_status
    ;;
  discard)
    cmd_discard
    ;;
  promote)
    cmd_promote
    ;;
  help|-h|--help)
    cmd_help
    ;;
  *)
    die "unknown command '$1' (try: nvim-exp help)"
    ;;
esac
