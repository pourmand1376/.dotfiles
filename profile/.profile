# add nix path to path if it exists
[ -d "$HOME/.local/share/nix-tools/bin" ] && export PATH="$HOME/.local/share/nix-tools/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# nix: nixapply = apply config, nixup = update everything + clean, nixgc = clean only
for _d in "$HOME/gitfolder/.dotfiles" "$HOME/.dotfiles"; do
  if [ -x "$_d/nix/apply.sh" ]; then
    alias nixapply="$_d/nix/apply.sh"
    alias nixup="$_d/nix/apply.sh update"
    alias nixgc="$_d/nix/apply.sh gc"
    break
  fi
done
unset _d

# Modern CLI replacements
# ------------------------------------------------------------

alias lg="lazygit"
alias gg="git-graph"
alias graph="serie"
alias serie="serie --protocol iterm"
#
#
alias c="claude"
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

# lazygit with the Catppuccin flavour matching macOS light/dark mode (like
# delta-themed). Leaves LG_CONFIG_FILE alone when a caller already set it,
# e.g. snacks.nvim, which themes lazygit from the nvim colorscheme.
lazygit() {
  if [ -n "$LG_CONFIG_FILE" ]; then
    command lazygit "$@"
    return
  fi
  local dir="$XDG_CONFIG_HOME/lazygit" flavour=latte
  defaults read -g AppleInterfaceStyle >/dev/null 2>&1 && flavour=mocha
  LG_CONFIG_FILE="$dir/config.yml,$dir/theme-$flavour.yml" command lazygit "$@"
}

#### --- PATH ---------------------
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# homebrew (formulae nix can't provide, e.g. mole): appended so nix wins on duplicates.
# ~/.zprofile only runs in login shells; this covers tmux/zellij/editor shells too.
case ":$PATH:" in
  *:/opt/homebrew/bin:*) ;;
  *) [ -d /opt/homebrew/bin ] && export PATH="$PATH:/opt/homebrew/bin:/opt/homebrew/sbin" ;;
esac

#### end of path variables

# yazi for bash and zsh
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

alias internet_check="~/gitfolder/.dotfiles/scripts/internet_check.py -p"
alias ic="netchecker"
alias nq="networkQuality -v"

alias info="fastfetch -c all"

alias remote="ssh -t main.insight-dev.amirpourmand.coder 'tmux new-session -A -s remote'"
