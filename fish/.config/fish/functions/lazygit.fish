function lazygit --description 'lazygit with Catppuccin flavour matching macOS appearance'
    if test -n "$LG_CONFIG_FILE"
        command lazygit $argv
        return
    end
    set -l dir $XDG_CONFIG_HOME/lazygit
    set -l flavour latte
    defaults read -g AppleInterfaceStyle >/dev/null 2>&1; and set flavour mocha
    LG_CONFIG_FILE="$dir/config.yml,$dir/theme-$flavour.yml" command lazygit $argv
end
