#!/usr/bin/env bash
# Usage: ./apply.sh [switch|update]
#   switch (default): build packages from flake.nix into ~/.local/share/nix-tools
#   update:           bump nixpkgs in flake.lock, then switch
set -euo pipefail

CONFIG_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$CONFIG_DIR")"
OUT_LINK="$HOME/.local/share/nix-tools"
NIX=(nix --extra-experimental-features "nix-command flakes")

switch() {
  mkdir -p "$HOME/.config/nix" "$HOME/.local/share"
  ln -sfn "$CONFIG_DIR/nix.conf" "$HOME/.config/nix/nix.conf"

  "${NIX[@]}" build "$CONFIG_DIR#default" --out-link "$OUT_LINK"

  "$OUT_LINK/bin/stow" -d "$REPO_DIR" -t "$HOME" profile

  echo "Nix packages applied: $(readlink "$OUT_LINK")"
}

case "${1:-switch}" in
  switch) switch ;;
  update)
    "${NIX[@]}" flake update --flake "$CONFIG_DIR"
    switch
    ;;
  *)
    echo "usage: $0 [switch|update]" >&2
    exit 1
    ;;
esac
