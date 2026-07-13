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

eval "$(zoxide init zsh --cmd cd)"

# https://github.com/starship/starship/issues/3418#issuecomment-1711630970
if [[ "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
    zle -N zle-keymap-select "";
fi

eval "$(starship init zsh)"


### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk
#

# Two regular plugins loaded without investigating.
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light Aloxaf/fzf-tab

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode


