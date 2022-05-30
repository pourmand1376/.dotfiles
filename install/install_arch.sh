manjaro

sudo pacman -Syu

#install lts kernel

#kde settings
# night mode

#ignore linux kernel updates
sudo nano /etc/pacman.conf
#IgnorePkg = linux
#and uncomment color line

sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

#https://github.com/fosskers/aura
#install aura
git clone https://aur.archlinux.org/aura-bin.git
cd aura-bin
makepkg
sudo pacman -U <the-package-file-that-makepkg-produces>

sudo aura -S zip unzip unrar net-tools terminator --noconfirm -x
sudo aura -S lftp --noconfirm

# sudo aura -S npm
# sudo npm install -g tldr

sudo aura -A tldr++ -x

# https://github.com/ohmyzsh/ohmyzsh
sudo aura -A zsh-theme-powerlevel10k-git
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
zsh

git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting 

git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions

git clone https://github.com/zsh-users/zsh-history-substring-search $ZSH_CUSTOM/plugins/zsh-history-substring-search

git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
# then add zsh-autosuggestions to .zshrc
### finish zsh plugins

nano syntax highlight
# https://github.com/scopatz/nanorc
sudo aura -S nano-syntax-highlighting

 sudo aura -S most     
echo 'export PAGER='most'' >> .profile  


sudo aura -S flameshot gvim smplayer texstudio gparted --noconfirm
curl -sLf https://spacevim.org/install.sh | bash

sudo aura -S  networkmanager-l2tp strongswan


sudo aura -A standardnotes-bin brave-bin skypeforlinux-stable-bin  vokoscreen-git github-desktop-bin megasync-bin visual-studio-code-bin gahshomar marktext-bin  --noconfirm -x
sudo aura -A mailspring --noconfirm -x
sudo aura -A anki gnome-clocks-git --noconfirm -x  
sudo aura -A stacer-bin --noconfirm -x
sudo aura -A motrix-bin --noconfirm -x
#sudo aura -A persepolis --noconfirm -x

#pdf software
sudo aura -A 	masterpdfeditor -x --noconfirm

sudo aura -A git-credential-manager-core-bin --noconfirm -x
git config --global credential.credentialStore secretservice

#git merge tool
sudo aura -S kdiff3 -x --noconfirm
git config --global merge.tool "kdiff3"

#separate because it needs java and it could cause problem
sudo aura -A jabref -x --noconfirm


sudo aura -A telegram-desktop-bin --noconfirm -x
 



# https://github.com/fzerorubigd/persian-fonts-linux
sh -c "$(curl -fsSL https://raw.githubusercontent.com/fzerorubigd/persian-fonts-linux/master/farsifonts.sh)"

# power saving
sudo aura -A auto-cpufreq --noconfirm
sudo systemctl enable auto-cpufreq
sudo systemctl start auto-cpufreq
# also note that tlp is automatically installed


sudo aura -A  protonvpn-cli --noconfirm
sudo aura -A cloudflare-warp-bin --noconfirm -x
sudo systemctl start warp-svc
sudo warp-cli register


# for monitoring network usuage by process
sudo aura -S nethogs

# for website 
# https://wiki.archlinux.org/title/Jekyll
aura -A ruby --noconfirm -x
# add environment variables 
gem install jekyll
gem install bundler	

# https://github.com/sandesh236/sleek--themes

# do not forget timeshift

# this is for win key to open launcher
sudo aura -A ksuperkey 
sudo aura -A spotify
sudo aura -A joplin-appimage -x  

#install touchegg and touche for touchpad management

#install blueman for bluetooth
sudo aura -S blueman

# https://github.com/EliverLara/terminator-themes

## tools for command line at datascience
sudo aura -S bat

# https://switowski.com/blog/favorite-cli-tools
# https://hackernoon.com/macbook-my-command-line-utilities-f8a121c3b019

## input-remapper 
## F11 -> Home, F12 -> End, (Escape or insert) + F11 -> F11, (Escape or insert) + F12 -> F12
## Caps lock -> Ctrl, alt gr -> alt_R
# disable touchpad when typing problem

# install optimus manager for better use of GPU



# Oh my tmux
# https://github.com/gpakosz/.tmux

cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
