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
              neovim
              yazi
              lazygit
              delta
              stow
              fastfetch
              btop
            ];
          };
        });
    };
}
