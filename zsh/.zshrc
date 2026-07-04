# load my aliases and common stuff
if [ -f ~/.profile ]; then
  source ~/.profile
fi

# ==============================================================================
# Private Configurations (Keep out of version control / Git)
# ==============================================================================

# my private stuff (not sync into git)
if [ -f ~/.localrc ]; then
  source ~/.localrc
fi

# fuzzy finder init
source <(fzf --zsh)


eval "$(starship init zsh)"

