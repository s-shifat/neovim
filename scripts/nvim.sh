set -euo pipefail

state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
stable_profile="${NVIM_STABLE_PROFILE:-$state_home/neovim/stable-profile}"

if [[ ! -x "$stable_profile/bin/nvim" ]]; then
  echo "nvim: stable Neovim profile is not initialized." >&2
  echo "Run:" >&2
  echo "  nvim-exp setup" >&2
  exit 1
fi

exec "$stable_profile/bin/nvim" "$@"
