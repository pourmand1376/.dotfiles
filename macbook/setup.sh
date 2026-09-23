# https://www.youtube.com/watch?v=GK7zLYAXdDs

# CLI tools (ffmpeg, neovim, ripgrep, lazygit, uv, tmux, ...) come from nix:
#   ../nix/apply.sh          install
#   ../nix/apply.sh update   update
# brew is only for GUI apps (casks) and the few formulae left in ./Brewfile.

# brew install --cask iterm2
brew install --cask wezterm
## brew installs
brew install iina # video player # utitlies -> Set as default
# brew install --cask alfred (replaced with raycast)
# brew install --cask rectangle (replaced with raycast) # removed in favor of Aerospace
brew install --cask visual-studio-code
brew install --cask obsidian
# brew install --cask firefox
# brew install --cask arc
# brew install --cask maccy (raycast replaced it)
brew install --cask raycast
#brew install --cask cheatsheat # needs vpn
brew install --cask keyclu

# ScreenZen Limit Screen Time on certain apps and websites

# to test
#brew install --cask kap # screen recording
# brew install --cask obs #(obs studio)
brew install --cask keka # file zip and archive utility
# set it as default
brew install --cask vlc # video player
#brew install --cask bartender # customize dock icons
# brew install jordanbaird-ice # customize dock icons (FOSS)
#brew install --cask hiddenbar # same as ice
# i use bartender

# install oh-my-zsh and oh-my-bash
# تقویم روزگار
# https://apps.apple.com/us/app/roozegar-%D8%B1%D9%88%D8%B2%DA%AF%D8%A7%D8%B1/id1171425651

# Nekoray
# https://github.com/abbasnaqdi/nekoray-macos/releases

# warp
# httppie
# pycharm ce
# bitwarden
# DBeaver
# fork https://git-fork.com/
brew install --cask keka # zip, rar files opener
# pages numbers keynote # from apple store

# reverse mouse and touchpad direction
brew install --cask unnaturalscrollwheels # this is better than scroll-reverser
#brew install scroll-reverser

# https://superuser.com/questions/18212/remapping-keys-for-the-mac
brew install --cask karabiner-elements

# cwebp test.jpg -o test.webp

# best pdf editor (free) - PDF Gear

# dropover - Drop files in place
# https://apps.apple.com/us/app/dropover-easier-drag-drop/id1355679052?mt=12

# relaxing sounds
#https://apps.apple.com/us/app/qi-fm-focus-relax-sounds/id1479696191?mt=12

# for timer just use pomodone or roundpie (update TickTick)

# amphetamine (not allow to sleep)

# https://github.com/ehsania/Persian-Glossaries-for-Apple-Dictionary
# https://github.com/wayneclub/Apple-Dictionary

# brew install --cask transmission #download torrent files
# no need for any of those since we have aria2

# folx for regular downloads

brew install --cask nikitabobko/tap/aerospace
# https://nikitabobko.github.io/AeroSpace/guide


brew install bruno # alternative to postman, insomnia, https://httpie.io/app

# orbstack asks for internet access which I don't like
# brew install orbstack ## alternative to docker desktop
brew install container # apple itself releases this
# then you just have to use `container system start`
# then install this to have docker command instead of container
brew install appautomaton/tap/docker-for-apple-container
mkdir -p /usr/local/bin
ln -sf /opt/homebrew/bin/container /usr/local/bin/container


#brew install --cask espanso ## text replacer
# use raycast as text replacer! use snippets.

brew install --cask macshot # best tool for screenshot and free and open source
# depcreated: drop over. cleanshot X

# Homerow
brew install pearcleaner # app cleaner


# ticktick, obsidian, chatgpt

# install lookaway (actually not, its annoying)

https://apps.apple.com/us/app/ticktick-to-do-list-calendar/id966085870?mt=12

# sound source https://rogueamoeba.com/soundsource/

# https://github.com/romkatv/powerlevel10k

# https://stackoverflow.com/questions/18393498/gitignore-all-the-ds-store-files-in-every-folder-and-subfolder
#Felt tip: Since you probably never want to include .DS_Store files, make a global rule. First, make a global .gitignore file somewhere, e.g.

echo .DS_Store >>~/.gitignore_global
#Now tell git to use it for all repositories:

git config --global core.excludesfile ~/.gitignore_global

# Add .env loading to ~/.zshrc
if ! grep -q "export \$(cat .env | xargs)" ~/.zshrc; then
  echo "" >>~/.zshrc
  echo "# Load .env file if it exists" >>~/.zshrc
  echo "if [ -f .env ]; then" >>~/.zshrc
  echo "    export \$(cat .env | xargs)" >>~/.zshrc
  echo "fi" >>~/.zshrc
fi

# Add NeoVim as default vim for mac
echo 'alias vim=nvim' >>~/.zshrc
echo 'alias vi=nvim' >>~/.zshrc
source ~/.zshrc

## add lazyvim

xcode-select --install
brew install --cask font-meslo-lg-nerd-font

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

## install zoxide (replacement for cd)
echo 'eval "$(zoxide init zsh --cmd cd)"' >>~/.zshrc

### install eza (alternative to ls)
cat >>~/.zshrc <<'EOF'

# eza: better ls
alias ls='eza --group-directories-first'
alias ll='eza -lh --git --group-directories-first'
alias la='eza -lah --git --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'
EOF

## to make it short

cat >>~/.zshrc <<'EOF'

# ------------------------------------------------------------
# Modern CLI replacements
# ------------------------------------------------------------

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

# zoxide: smarter cd
eval "$(zoxide init zsh --cmd cd)"

# btop: better top
alias top='btop'

# trash: safer rm
alias rm='trash'
alias del='trash'

# tldr: simpler man pages
alias man='tldr'
EOF

git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global merge.conflictstyle zdiff3

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)


# for for code. a very good font.
brew install --cask font-jetbrains-mono-nerd-font

# then add vi mode for zsh and bash
# for recording add OBS + Presenter-overlay for camera
#
#
brew install --cask tomatobar # A pomodoro time. TickTick does it as well
## install lazyvim

xcode-select --install
brew install --cask font-meslo-lg-nerd-font

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# end of install lazyvim
#
#
# also you need to have BetterDisplay for external monitors to show better.
# and maybe superwhisper
