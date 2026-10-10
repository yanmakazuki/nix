{ config, lib, pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "yanmakazuki";

  system.stateVersion = 7;
  nix.package = pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Yaziなど、シェルから起動するアプリの編集用コマンド。
  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  imports = [ ./macos.nix ./chrome.nix ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "google-chrome" "chatgpt" "vscode" ];

  environment.systemPackages = [
    pkgs.google-chrome
    pkgs.chatgpt
    pkgs.vscode
  ];

  # Home Managerの対象ユーザーはmacOSで作成済みのアカウントを指定する。
  users.users.${config.system.primaryUser}.home = "/Users/${config.system.primaryUser}";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    users.${config.system.primaryUser} = import ./home.nix;
  };
}
