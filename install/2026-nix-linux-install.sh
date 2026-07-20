#!/bin/bash

sudo apt update -y

rm ~/.bashrc ~/.zshrc ~/.tmux.conf

curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon

git clone https://github.com/pourmand1376/.dotfiles

./.dotfiles/nix/apply.sh

export PATH="$HOME/.local/share/nix-tools/bin:$PATH"

cd .dotfiles

stow profile
stow starship
stow zsh
stow tmux
stow nvim
stow lazygit
