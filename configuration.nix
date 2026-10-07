{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "yanmakazuki";

  system.stateVersion = 7;
  nix.package = pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [ ./captured-defaults.nix ./chrome.nix ./apps.nix ];
}
