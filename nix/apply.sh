#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config/nix"
mkdir -p "$HOME/.local/share"

ln -sfn "$CONFIG_DIR/nix.conf" "$HOME/.config/nix/nix.conf"

nix build "$CONFIG_DIR#default" \
  --out-link "$HOME/.local/share/nix-tools"

echo "Nix configuration and packages applied."
