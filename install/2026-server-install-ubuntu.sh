# new server install for apt. considering everything important.
#
#
# First clone my .dotfiles directory into home
#
sudo apt update -y

sudo apt install stow build-essential neofetch -y

sudo apt install curl git zsh neovim -y

# install starship zsh
curl -sS https://starship.rs/install.sh | sh

# remove .zshrc and .tmux.conf
rm ~/.zshrc ~/.tmux.conf

curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg
echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list
sudo apt update -y
sudo apt install yazi -y

stow profile
stow starship
stow zsh
stow tmux
stow nvim
stow lazygit
