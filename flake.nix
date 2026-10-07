{
  description = "macOS settings for Kazukis-MacBook-Air";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-darwin, ... }: {
    darwinConfigurations."Kazukis-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ ./configuration.nix ];
    };
  };
}
