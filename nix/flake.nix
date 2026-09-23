{
  description = "Amir CLI Packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nix-darwin, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # unfree packages allowed by name
      allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
        "claude-code"
        "keka"
        "mos"
      ];
    in
    {
      # Linux (and any machine without nix-darwin): ./apply.sh builds this into ~/.local/share/nix-tools
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
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
          { nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate; }
        ];
      };
    };
}
