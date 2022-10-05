sudo apt install curl git zsh htop
mkdir -p ~/.plugins/

# make zsh default
chsh -s $(which zsh)

zsh 

sudo apt install stow
git clone https://github.com/pourmand1376/.dotfiles
cd ~/.dotfiles
stow antigen

cd ~
# install antigen
curl -L git.io/antigen > .antigen.zsh

source .antigen.zsh
echo "source ~/.antigen.zsh" > ~/.zshrc
echo "source ~/.antigenrc" > ~/.zshrc
