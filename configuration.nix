{ config, lib, openbot, pkgs, ... }:
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
    builtins.elem (lib.getName pkg) [ "google-chrome" "vscode" "spotify" ];

  environment.systemPackages = [
    pkgs.ghostty-bin
    pkgs.google-chrome
    pkgs.vscode
    pkgs.spotify
  ];

  users.users.${primaryUser}.home = "/Users/${primaryUser}";
  home-manager = {
    extraSpecialArgs = { inherit openbot; };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    users.${primaryUser} = import ./home.nix;
  };
}
