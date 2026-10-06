#!/usr/bin/env bash
# Usage: ./apply.sh [switch|update|gc]
#   switch (default): macOS -> darwin-rebuild switch (packages, brew, App Store, macOS settings)
#                     Linux -> build packages into ~/.local/share/nix-tools
#   update:           bump inputs in flake.lock, switch, upgrade brew, then gc
#   gc:               delete generations older than 30 days and everything in /nix/store nothing uses
set -euo pipefail

CONFIG_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$CONFIG_DIR")"
OUT_LINK="$HOME/.local/share/nix-tools"
NIX=(nix --extra-experimental-features "nix-command flakes")

# stow packages (top-level folders of the repo) linked into $HOME on every apply
STOW_COMMON=(profile zsh starship tmux nvim lazygit)
STOW_MAC=(bash git claude flashspace hammerspoon karabiner-elements neru wezterm zellij)
# top-level folders that are not stow packages
STOW_SKIP=(archive install mac-server macbook nix scripts)

ensure_homebrew() {
  # nix-darwin's homebrew module needs brew to exist; it does not install it
  [ -x /opt/homebrew/bin/brew ] || [ -x /usr/local/bin/brew ] && return
  echo "Homebrew not found, installing it..."
  # installer runs as the user and needs cached sudo in NONINTERACTIVE mode
  sudo -v
  # Apple's curl: it goes through the VPN, nix's curl does not
  NONINTERACTIVE=1 /bin/bash -c "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

stow_all() {
  local stow="$1"; shift
  # -R also removes links to files deleted from the repo
  # README.md: ~/.hammerspoon is a hammerflow clone with its own README
  "$stow" -R -d "$REPO_DIR" -t "$HOME" --ignore='README\.md' --ignore='\.DS_Store' "$@"
  echo "Stowed: $*"

  # warn about new top-level folders that are in no list, so nothing is missed
  local dir name
  for dir in "$REPO_DIR"/*/; do
    name="$(basename "$dir")"
    case " ${STOW_COMMON[*]} ${STOW_MAC[*]} ${STOW_SKIP[*]} " in
      *" $name "*) ;;
      *) echo "WARNING: '$name' is not in STOW_COMMON/STOW_MAC/STOW_SKIP in apply.sh" >&2 ;;
    esac
  done
}

ensure_wezterm_plugins() {
  # wezterm 20240203 can't fetch plugins over https itself, so wezterm.lua loads a local clone
  local dir="$HOME/.local/share/wezterm-plugins/wezterm-cmdpicker"
  [ -d "$dir/.git" ] && return
  mkdir -p "$(dirname "$dir")"
  git clone https://github.com/abidibo/wezterm-cmdpicker "$dir"
}

ensure_codex_config() {
  # Codex rewrites config.toml with private state (trusted project paths, hook hashes),
  # so it stays untracked; only pin the approval settings at the top level
  local cfg="$HOME/.codex/config.toml" kv key
  mkdir -p "$(dirname "$cfg")"
  touch "$cfg"
  for kv in 'approval_policy = "on-request"' 'approvals_reviewer = "auto_review"' 'sandbox_mode = "workspace-write"'; do
    key="${kv%% =*}"
    # only touch the top-level key: lines before the first [table]
    if awk -v k="$key" '/^\[/{exit} $0 ~ "^"k" *=" {f=1} END{exit !f}' "$cfg"; then
      awk -v k="$key" -v kv="$kv" '/^\[/{t=1} !t && $0 ~ "^"k" *=" {$0=kv} 1' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
    else
      { echo "$kv"; cat "$cfg"; } > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
    fi
  done
}

switch_darwin() {
  ensure_homebrew

  # Both Macs intentionally use the same shared configuration.
  local flake="$CONFIG_DIR#AmirMac"
  local primary_user
  primary_user="$(id -un)"

  # App Store apps are slow and need an App Store sign-in, so ask (default: skip)
  local mas=0 answer
  if [ -t 0 ]; then
    read -r -p "Install App Store apps too? [y/N] " answer
    case "$answer" in [yY]*) mas=1 ;; esac
  fi
  if command -v darwin-rebuild >/dev/null; then
    sudo env "NIX_PRIMARY_USER=$primary_user" "NIX_MAS_APPS=$mas" darwin-rebuild switch --impure --flake "$flake"
  else
    # first run: build nix-darwin, then use its darwin-rebuild
    local tmp
    tmp="$(mktemp -d)/system"
    NIX_PRIMARY_USER="$primary_user" NIX_MAS_APPS="$mas" "${NIX[@]}" build --impure "$CONFIG_DIR#darwinConfigurations.AmirMac.system" --out-link "$tmp"
    sudo env "NIX_PRIMARY_USER=$primary_user" "NIX_MAS_APPS=$mas" "$tmp/sw/bin/darwin-rebuild" switch --impure --flake "$flake"
  fi

  # packages now live in /run/current-system/sw; drop the old buildEnv link
  [ -L "$OUT_LINK" ] && rm "$OUT_LINK"

  stow_all /run/current-system/sw/bin/stow "${STOW_COMMON[@]}" "${STOW_MAC[@]}"
  ensure_wezterm_plugins
  ensure_codex_config
}

switch_linux() {
  "${NIX[@]}" build "$CONFIG_DIR#default" --out-link "$OUT_LINK"
  stow_all "$OUT_LINK/bin/stow" "${STOW_COMMON[@]}"
  echo "Nix packages applied: $(readlink "$OUT_LINK")"
}

switch() {
  mkdir -p "$HOME/.config/nix" "$HOME/.local/share"
  ln -sfn "$CONFIG_DIR/nix.conf" "$HOME/.config/nix/nix.conf"

  if [ "$(uname)" = Darwin ]; then switch_darwin; else switch_linux; fi
}

gc() {
  # old generations first (keeps 30 days of rollback), then unreferenced store paths
  if [ "$(uname)" = Darwin ]; then
    sudo nix-collect-garbage --delete-older-than 30d
  else
    nix-collect-garbage --delete-older-than 30d
  fi
  du -sh /nix/store 2>/dev/null || true
}

case "${1:-switch}" in
  switch) switch ;;
  update)
    "${NIX[@]}" flake update --flake "$CONFIG_DIR"
    switch
    [ "$(uname)" = Darwin ] && brew update && brew upgrade
    gc
    ;;
  gc) gc ;;
  *)
    echo "usage: $0 [switch|update|gc]" >&2
    exit 1
    ;;
esac
