{ config, pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "yanmakazuki";

  system.stateVersion = 7;
  nix.package = pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [ ./macos.nix ./chrome.nix ./apps.nix ];

  # Home Managerの対象ユーザーはmacOSで作成済みのアカウントを指定する。
  users.users.${config.system.primaryUser}.home = "/Users/${config.system.primaryUser}";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    users.${config.system.primaryUser} = import ./home.nix;
  };
}
