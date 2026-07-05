# Modern CLI replacements
# ------------------------------------------------------------

alias lg="lazygit"

# eza: better ls
alias ls='eza --group-directories-first --icons'
alias ll='eza -lh --git --group-directories-first --icons'
alias la='eza -lah --git --group-directories-first --icons'
alias lt='eza --tree --level=2 --group-directories-first'

alias tree='eza --tree --level=2'

# bat: better cat
alias cat='bat'
alias less='bat --paging=always'

# ripgrep: better grep
alias grep='rg'

# fd: better find
alias find='fd'

# btop: better top
alias top='btop'

# trash: safer rm
alias rm='trash'
alias del='trash'

# tldr: simpler man pages
alias man='tldr'
alias v='nvim'
alias vim='nvim'

# for lazygit to know the directoy of config
export XDG_CONFIG_HOME="$HOME/.config"

# yazi for bash and zsh
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}
