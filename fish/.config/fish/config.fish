# Fish config (mirrors zsh/.zshrc + profile/.profile). Functions live in functions/.

# ---- PATH ---------------------------------------------------------------
fish_add_path --move --path $HOME/.local/share/nix-tools/bin $HOME/.local/bin
fish_add_path --path $HOME/.cargo/bin $HOME/.opencode/bin $HOME/.kilo/bin $HOME/.bun/bin
fish_add_path --append --path /opt/homebrew/bin /opt/homebrew/sbin /Applications/Obsidian.app/Contents/MacOS

set -gx XDG_CONFIG_HOME $HOME/.config
set -gx EDITOR nvim
set -gx OLLAMA_HOST http://127.0.0.1:2222
set -gx BUN_INSTALL $HOME/.bun

# ---- private stuff (shared with zsh, not in git) ------------------------
load_env_file $HOME/.localrc

if status is-interactive
    set -g fish_greeting
    fish_vi_key_bindings

    # ---- aliases ----------------------------------------------------------
    for d in $HOME/gitfolder/.dotfiles $HOME/.dotfiles
        if test -x $d/nix/apply.sh
            alias nixapply "$d/nix/apply.sh"
            alias nixup "$d/nix/apply.sh update"
            alias nixgc "$d/nix/apply.sh gc"
            break
        end
    end

    alias lg lazygit
    alias gg git-graph
    alias graph serie
    alias serie "serie --protocol iterm"
    alias c claude
    alias t tuios
    alias ls 'eza --group-directories-first --icons=auto'
    alias ll 'eza -lh --git --group-directories-first --icons=auto'
    alias la 'eza -lah --git --group-directories-first --icons=auto'
    alias lt 'eza --tree --level=2 --group-directories-first'
    alias tree 'eza --tree --level=2'
    alias cat bat
    alias less 'bat --paging=always'
    alias grep rg
    alias find fd
    alias top btop
    alias rm trash
    alias del trash
    alias man tldr
    alias v nvim
    alias vim nvim
    alias internet_check "~/gitfolder/.dotfiles/scripts/internet_check.py -p"
    alias ic netchecker
    alias nq "networkQuality -v"
    alias info "fastfetch -c all"
    alias remote "ssh -t main.insight-dev.amirpourmand.coder 'tmux new-session -A -s remote'"

    # ---- tools ------------------------------------------------------------
    command -q zoxide; and zoxide init fish --cmd cd | source
    command -q starship; and starship init fish | source

    # fzf.fish: Ctrl+R history, Ctrl+Alt+F files, Ctrl+Alt+L git log, etc.
    # keep vi-mode working with its bindings in both modes
    if functions -q fzf_configure_bindings
        fzf_configure_bindings --directory=\ct
    end
end
