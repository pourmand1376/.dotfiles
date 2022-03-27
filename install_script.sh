# rpm fusion
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo rpm --import https://raw.githubusercontent.com/UnitedRPMs/unitedrpms/master/URPMS-GPG-PUBLICKEY-Fedora
sudo dnf -y install https://github.com/UnitedRPMs/unitedrpms/releases/download/19/unitedrpms-$(rpm -E %fedora)-19.fc$(rpm -E %fedora).noarch.rpm



sudo dnf install terminator unrar zsh git

chsh -s $(which zsh)
# https://github.com/zsh-users/antigen
curl -L https://raw.githubusercontent.com/zsh-users/antigen/master/bin/antigen.zsh > ~/.plugins/antigen.zsh

echo "# Load Antigen
source ~/.plugins/antigen.zsh
# Load Antigen configurations
antigen init ~/.antigenrc

source ~/.profile" > .zshrc


echo "antigen use oh-my-zsh

# Load bundles from the default repo (oh-my-zsh)
antigen bundle git
antigen bundle command-not-found
antigen bundle docker

# Load bundles from external repos
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

# Select theme
antigen theme romkatv/powerlevel10k

# Tell Antigen that you're done
antigen apply

" > .antigenrc

## https://github.com/EliverLara/terminator-themes

sudo dnf install most
echo 'export PAGER='most'' >> .profile

sudo dnf install gparted flameshot


sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/

sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

sudo dnf install brave-browser
sudo dnf install telegram

# skype
sudo curl -o /etc/yum.repos.d/skype-stable.repo https://repo.skype.com/rpm/stable/skype-stable.repo
sudo dnf install skypeforlinux

sudo dnf install timeshift
sudo dnf install backintime-gnome


# https://github.com/fzerorubigd/persian-fonts-linux
sh -c "$(curl -fsSL https://raw.githubusercontent.com/fzerorubigd/persian-fonts-linux/master/farsifonts.sh)"

# cht.sh
curl https://cht.sh/:cht.sh | sudo tee /usr/local/bin/cht.sh
chmod +x /usr/local/bin/cht.sh

# install tldr ++
curl -OL https://github.com/isacikgoz/tldr/releases/download/v0.5.0/tldr_0.5.0_linux_amd64.tar.gz
sudo tar xvf tldr_0.5.0_linux_amd64.tar.gz -C /usr/bin

sudo dnf install kdiff3
git config --global merge.tool "kdiff3"
git config --global user.name "Amir Pourmand"
git config --global user.email "pourmand1376@gmail.com"

sudo dnf install vlc
sudo dnf install smplayer
sudo dnf install smplayer-themes

sudo dnf copr enable joseexposito/touchegg
sudo dnf install touchegg
sudo flatpak install touche
