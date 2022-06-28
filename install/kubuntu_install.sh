sudo apt instal curl git zsh
mkdir -p ~/.plugins/

# make zsh default
chsh -s $(which zsh)
# install antigen
curl -L git.io/antigen > antigen.zsh

# install kitty
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# make kitty default terminal emulator
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator `which kitty` 50
sudo update-alternatives --config x-terminal-emulator

sudo apt install tldr
sudo apt install most
export PAGER='most' >> .profile

sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

sudo apt install neofetch
sudo apt install kdiff3

sudo apt install vim
# install neovim from its website!

sudo apt install timeshift
sudo apt install backintime-common


# install touchegg
# https://github.com/JoseExposito/touchegg/releases

# Download Git SCM from website then set
# https://github.com/GitCredentialManager/git-credential-manager
git config --global credential.credentialStore secretservice



# install miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh

# install
conda init zsh
conda init bash

# adding conda-forge
conda config --add channels conda-forge
conda config --set channel_priority strict

