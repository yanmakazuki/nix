{ config, lib, pkgs, ... }:
let
  primaryUser = config.system.primaryUser;
in
{
  imports = [ ./macos.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "google-chrome" "vscode" "spotify" "openbot" ];

  system.primaryUser = "yanmakazuki";
  system.stateVersion = 7;

  nix.package = pkgs.lix;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  environment.systemPackages = with pkgs; [
    ghostty-bin
    google-chrome
    vscode
    spotify
  ];

  users.users.${primaryUser}.home = "/Users/${primaryUser}";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    users.${primaryUser} = import ./home.nix;
  };
}
