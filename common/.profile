# Modern CLI replacements
# ------------------------------------------------------------

alias lg="lazygit"

# eza: better ls
alias ls='eza --group-directories-first'
alias ll='eza -lh --git --group-directories-first'
alias la='eza -lah --git --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'

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
