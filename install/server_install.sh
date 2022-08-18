# Just install brew as a package manager and then install everything else
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install zsh
brew install fzf
brew install ncdu

brew install stow

brew install neovim
brew install z # for tracking history and smart cd

# also you should use `realpath` command to see full path for a given item
