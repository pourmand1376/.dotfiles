# use this script to setup mac

brew install stow

cd ~/gitfolder/.dotfiles

stow aerospace -t $HOME
stow git -t $HOME
stow karabiner-elements -t $HOME