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
 # https://www.youtube.com/watch?v=VQ6MVky9EUk

sudo apt install gnome-shell-extensions
sudo apt install gnome-shell-extension-manager

