#!/bin/sh
# macOS desktop notifications for Claude Code that survive zellij.
#
# Claude Code's preferredNotifChannel writes an OSC escape sequence (OSC 9/99/777)
# to the terminal. Zellij does not forward those to the host terminal, so they are
# silently dropped. This hook bypasses the terminal and talks to Notification Center
# directly, which works the same inside or outside zellij.
set -u

command -v terminal-notifier >/dev/null 2>&1 || exit 0

payload="$(cat)"
get() { printf '%s' "$payload" | jq -r "$1" 2>/dev/null; }

message="$(get '.message // "Claude needs you"')"
ntype="$(get '.notification_type // "notification"')"
cwd="$(get '.cwd // ""')"
project="$(basename "${cwd:-$PWD}")"

case "$ntype" in
  permission_prompt|worker_permission_prompt) sound="Funk" ;;
  agent_completed)                            sound="Glass" ;;
  *)                                          sound="Ping" ;;
esac

terminal-notifier \
  -title "Claude Code — $project" \
  -subtitle "${ZELLIJ_SESSION_NAME:-terminal}" \
  -message "$message" \
  -group "claude-code-${ZELLIJ_SESSION_NAME:-default}-${ZELLIJ_PANE_ID:-0}" \
  -sound "$sound" \
  -activate com.github.wez.wezterm \
  >/dev/null 2>&1

exit 0
