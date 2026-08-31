set -euo pipefail

stable_repo="${NVIM_STABLE_REPO:-$HOME/projects/neovim}"
next_worktree="${NVIM_NEXT_WORKTREE:-$HOME/projects/neovim-next}"
stable_branch="${NVIM_STABLE_BRANCH:-main}"

die() {
  echo "nvim-exp: $*" >&2
  exit 1
}

ensure_stable_repo() {
  git -C "$stable_repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
    die "stable repository not found at $stable_repo"
}

ensure_next_worktree() {
  git -C "$next_worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
    die "no active experiment worktree at $next_worktree"
}

current_branch() {
  git -C "$1" branch --show-current
}

is_dirty() {
  [[ -n "$(git -C "$1" status --porcelain)" ]]
}

ensure_stable_ready() {
  ensure_stable_repo

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

cmd_new() {
  local name="${1:-}"

  [[ -n "$name" ]] ||
    die "usage: nvim-exp new <name>"

  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] ||
    die "experiment name may contain only letters, numbers, '.', '_' and '-'"

  ensure_stable_ready

  if [[ -e "$next_worktree" ]]; then
    die "an experiment worktree already exists at $next_worktree"
  fi

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
  echo
  echo "Launch it with:"
  echo "  nvim-next"
}

cmd_status() {
  ensure_stable_repo

  local stable_current
  local stable_commit

  stable_current="$(current_branch "$stable_repo")"
  stable_commit="$(git -C "$stable_repo" rev-parse --short HEAD)"

  echo "Stable"
  echo "  repo:       $stable_repo"
  echo "  branch:     $stable_current"
  echo "  commit:     $stable_commit"

  if is_dirty "$stable_repo"; then
    echo "  working:    modified"
  else
    echo "  working:    clean"
  fi

  echo

  if git -C "$next_worktree" rev-parse \
    --is-inside-work-tree >/dev/null 2>&1
  then
    local next_branch
    local next_commit

    next_branch="$(current_branch "$next_worktree")"
    next_commit="$(git -C "$next_worktree" rev-parse --short HEAD)"

    echo "Experiment"
    echo "  worktree:   $next_worktree"
    echo "  branch:     $next_branch"
    echo "  commit:     $next_commit"

    if is_dirty "$next_worktree"; then
      echo "  working:    modified"
    else
      echo "  working:    clean"
    fi
  else
    echo "Experiment"
    echo "  active:     none"
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

  printf "Discard this experiment permanently? [y/N] "
  read -r answer

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
    echo >&2
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
  echo
  echo "Stable source is now:"
  git -C "$stable_repo" log -1 --oneline
  echo
  echo "Installed Neovim has NOT been changed automatically."
  echo "Deploy the new stable revision through your dotfiles"
  echo "or upgrade the standalone Nix installation."
}

cmd_help() {
  cat <<'HELP'
Usage:
  nvim-exp new <name>
  nvim-exp status
  nvim-exp discard
  nvim-exp promote

Commands:
  new       Create experiment/<name> in ~/projects/neovim-next
  status    Show stable and experimental Git state
  discard   Permanently remove the active experiment
  promote   Build and fast-forward merge the experiment into main

Typical workflow:

  nvim-exp new keybind
  nvim-next

  # Edit/test in ~/projects/neovim-next
  # Lua-only changes need no rebuild.

  cd ~/projects/neovim-next
  git add .
  git commit -m "feat: change keybinding"

  cd ~
  nvim-exp promote
HELP
}

case "${1:-help}" in
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
