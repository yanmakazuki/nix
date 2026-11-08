{
  description = "macOS settings for Kazukis-MacBook-Air";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    openbot.url = "github:nightly-labs/openbot";
    openbot.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-darwin, home-manager, openbot, ... }: {
    darwinConfigurations."Kazukis-MacBook-Air" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit openbot; };
      modules = [
        ./configuration.nix
        home-manager.darwinModules.home-manager
      ];
    };
  };
}
