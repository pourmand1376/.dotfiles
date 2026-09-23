{
  description = "Amir CLI Packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildEnv {
            name = "my-packages";

            paths = with pkgs; [
              # shell & core
              git
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
              fastfetch
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
              hugo

              # archives
              unzip
              _7zz # `7zz`

              # dev / cloud
              kubectl
              k9s
              lazydocker
              gemini-cli
              exercism
              rtk
            ] ++ lib.optionals stdenv.isDarwin [
              dockutil
              terminal-notifier
            ];
          };
        });
    };
}
