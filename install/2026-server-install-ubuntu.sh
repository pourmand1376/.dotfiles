# new server install for apt. considering everything important.
#
#
# First clone my .dotfiles directory into home
#
sudo apt update -y

sudo apt install stow build-essential neofetch

sudo apt install curl git zsh neovim

# install starship zsh
curl -sS https://starship.rs/install.sh | sh

stow common
stow starship
stow zsh
stow tmux
stow nvim
stow lazygit
