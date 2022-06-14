sudo apt update

# then install nvidia-drivers from additional drivers tab

# to switch between nvidia and prime use


# install kitty from here
# https://sw.kovidgoyal.net/kitty/binary/

# sudo prime-select nvidia or sudo prime-select intel
sudo apt instal curl git zsh
mkdir -p ~/.plugins/


# here I should put terminal settings



# make kitty default terminal emulator
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator `which kitty` 50
sudo update-alternatives --config x-terminal-emulator


sudo apt install most
export PAGER='most' >> .profile



sudo apt install flatpak
sudo apt install gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo


sudo apt install neofetch
sudo apt install neovim 
sudo apt install kdiff3


git config --global merge.tool "kdiff3"
git config --global user.name "Amir Pourmand"
git config --global user.email "pourmand1376@gmail.com"


# Download Git SCM from website then set
# https://github.com/GitCredentialManager/git-credential-manager
git config --global credential.credentialStore secretservice

# make gnome like macos

sudo apt install gnome-shell-extensions
sudo apt install gnome-shell-extension-manager
# install dconf editor for more options


sudo apt install timeshift
sudo apt install backintime-common

# install GSConnect in place of KDE Connect

## https://github.com/vinceliuice/WhiteSur-gtk-theme
# install kite
bash -c "$(wget -q -O - https://linux.kite.com/dls/linux/current)"

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

# installing docker! 

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# post-install for docker to make it run without sudo

sudo groupadd docker
sudo usermod -aG docker $USER


# install tldr
# install cheat.sh
sudo apt install input-remapper
# config remapper


# I can do these things using nix
# https://www.youtube.com/watch?v=70YMTHAZyy4

sudo apt install pavucontrol
