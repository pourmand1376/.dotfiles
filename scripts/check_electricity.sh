#!/usr/bin/env bash
# Launcher for check_electricity.py — safe to call from cron.
# cron runs with a minimal PATH, so we set one that finds python3 and osascript.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# cron does not read shell rc files, so load secrets (ELEC_TOKEN, ELEC_BILL_ID)
# from ~/.localrc ourselves.
if [ -f "$HOME/.localrc" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.localrc"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec python3 "$SCRIPT_DIR/check_electricity.py" "$@"
