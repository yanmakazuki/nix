{
  description = "macOS settings for Kazukis-MacBook-Air";

  inputs = {
    # リリース番号を固定せず、更新時にunstableブランチの最新を取得する。
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nix-darwinも最新の開発ブランチに追従する。
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-darwin, ... }: {
    darwinConfigurations."Kazukis-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ ./configuration.nix ];
    };
  };
}
