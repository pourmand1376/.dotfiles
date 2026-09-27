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

switch_darwin() {
  local flake="$CONFIG_DIR#$(scutil --get LocalHostName)"
  if command -v darwin-rebuild >/dev/null; then
    sudo darwin-rebuild switch --flake "$flake"
  else
    # first run: build nix-darwin, then use its darwin-rebuild
    local tmp
    tmp="$(mktemp -d)/system"
    "${NIX[@]}" build "$CONFIG_DIR#darwinConfigurations.$(scutil --get LocalHostName).system" --out-link "$tmp"
    sudo "$tmp/sw/bin/darwin-rebuild" switch --flake "$flake"
  fi

  # packages now live in /run/current-system/sw; drop the old buildEnv link
  [ -L "$OUT_LINK" ] && rm "$OUT_LINK"

  /run/current-system/sw/bin/stow -d "$REPO_DIR" -t "$HOME" profile
}

switch_linux() {
  "${NIX[@]}" build "$CONFIG_DIR#default" --out-link "$OUT_LINK"
  "$OUT_LINK/bin/stow" -d "$REPO_DIR" -t "$HOME" profile
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
