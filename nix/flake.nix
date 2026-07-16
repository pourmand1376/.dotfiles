{
  description = "Amir CLI Packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
    system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    packages.${system}.default = pkgs.buildEnv {
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
      ];
    };
  };
}
