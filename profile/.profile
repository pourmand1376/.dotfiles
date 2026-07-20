# add nix path to path if it exists
[ -d "$HOME/.local/share/nix-tools/bin" ] && export PATH="$HOME/.local/share/nix-tools/bin:$PATH"

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
export EDITOR=nvim

#### --- PATH ---------------------
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

#### end of path variables

# yazi for bash and zsh
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

alias internet_check="~/gitfolder/.dotfiles/scripts/internet_check.sh -p"
alias ic="internet_check"
alias nq="networkQuality -v"

alias info="fastfetch -c all"

alias remote="ssh -t main.portal-dev.amirpourmand.coder 'tmux new-session -A -s remote'"
