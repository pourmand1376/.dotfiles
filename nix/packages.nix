# CLI packages shared by macOS (nix-darwin) and Linux (buildEnv in flake.nix).
pkgs:
with pkgs;
[
  # shell & core (git: macOS ships /usr/bin/git; Linux distros ship their own)
  ripgrep
  fd
  jq
  bat
  tmux
  fzf
  zoxide
  eza
  starship
  stow
  tlrc # provides `tldr`
  yank
  wget
  aria2
  mosh
  just

  # editor & file managers
  neovim
  tree-sitter
  yazi

  # git
  lazygit
  delta
  gh
  glab
  git-graph
  serie
  onefetch
  pre-commit

  # system monitoring / disk
  btop
  htop
  dua

  # languages & runtimes
  go
  nodejs # includes npm, npx, corepack
  prettier
  uv

  # media, docs, images
  ffmpeg
  imagemagick
  libwebp # cwebp, dwebp
  hugo # pinned to 0.148.2 in flake.nix (matches deploy HUGO_VERSION)

  # archives
  unzip
  _7zz # `7zz`

  # dev / cloud
  kubectl
  k9s
  lazydocker
  exercism
  rtk

  # AI coding agent (updated by `nixup`, not by its own updater); codex + gemini-cli: brew
  claude-code
]
++ lib.optionals stdenv.hostPlatform.isDarwin [
  terminal-notifier
]
