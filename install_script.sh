# rpm fusion
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install terminator unrar zsh

chsh -s $(which zsh)
# https://github.com/zsh-users/antigen
curl -L https://raw.githubusercontent.com/zsh-users/antigen/master/bin/antigen.zsh > .plugins/antigen.zsh

echo "# Load Antigen
source .plugins/antigen.zsh
# Load Antigen configurations
antigen init ~/.antigenrc" > .zshrc


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

sudo dnf install akmod-nvidia

sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/

sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

sudo dnf install brave-browser
