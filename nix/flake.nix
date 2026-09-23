{
  description = "Amir CLI Packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hugo pinned to 0.148.2 to match the site's deploy HUGO_VERSION
    nixpkgs-hugo.url = "github:NixOS/nixpkgs/648f70160c03151bc2121d179291337ad6bc564b";
  };

  outputs = { nixpkgs, nix-darwin, nixpkgs-hugo, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # unfree packages allowed by name
      allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
        "claude-code"
        "keka"
        "mos"
      ];

      hugoOverlay = final: prev: {
        hugo = nixpkgs-hugo.legacyPackages.${prev.stdenv.hostPlatform.system}.hugo;
      };
    in
    {
      # Linux (and any machine without nix-darwin): ./apply.sh builds this into ~/.local/share/nix-tools
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ hugoOverlay ];
            config.allowUnfreePredicate = allowUnfreePredicate;
          };
        in
        {
          default = pkgs.buildEnv {
            name = "my-packages";
            paths = import ./packages.nix pkgs;
          };
        });

      # macOS: ./apply.sh runs darwin-rebuild with this
      darwinConfigurations.AmirWork = nix-darwin.lib.darwinSystem {
        modules = [
          ./darwin.nix
          {
            nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
            nixpkgs.overlays = [ hugoOverlay ];
          }
        ];
      };
    };
}
