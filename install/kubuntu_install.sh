sudo apt install curl git zsh unrar htop
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

sudo apt install gparted flameshot

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



# Docker

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

sudo mkdir -p /etc/docker

## for not coflicting with sharif dhcp
echo '{
	"registry-mirrors": ["https://registry.docker.ir"],
	"bip": "10.10.2.1/24",
	"ipv6": false
}' | sudo tee /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker

# docker without sudo
sudo groupadd docker
sudo usermod -aG docker $USER

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

