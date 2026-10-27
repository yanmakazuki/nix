{ config, lib, pkgs, ... }:
let
  primaryUser = config.system.primaryUser;
in
{
  imports = [ ./macos.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "yanmakazuki";

  system.stateVersion = 7;
  nix.package = pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "google-chrome" "grok-build" "vscode" "cursor" "spotify" ];

  environment.systemPackages = [
    pkgs.ghostty-bin
    pkgs.google-chrome
    pkgs.vscode
    pkgs.code-cursor
    pkgs.spotify
  ];

  users.users.${primaryUser}.home = "/Users/${primaryUser}";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    users.${primaryUser} = import ./home.nix;
  };
}
