{ ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "yanmakazuki";

  # 初回導入時の互換性バージョン。通常は更新しない。
  system.stateVersion = 7;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 読み取った現在値。手動の上書きには lib.mkForce を使う。
  imports = [ ./captured-defaults.nix ];
}
