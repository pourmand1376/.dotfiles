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
  tuios # terminal window manager
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
]
++ lib.optionals stdenv.hostPlatform.isDarwin [
  terminal-notifier
]
# macOS gets rtk from brew: nixpkgs marks it unfree (BUSL), so it is never in the binary
# cache and every bump downloads ~2 GB of Rust/clang to compile it
++ lib.optionals stdenv.hostPlatform.isLinux [
  rtk
]
