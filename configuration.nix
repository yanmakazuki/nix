{ pkgs, ... }:
{
  # Apple Silicon搭載Mac向けに構成をビルドする。
  nixpkgs.hostPlatform = "aarch64-darwin";
  # Dockなどのユーザー設定を適用する対象ユーザー。
  system.primaryUser = "yanmakazuki";

  # 初回導入時の互換性バージョン。通常は更新しない。
  system.stateVersion = 7;
  # 取得したNixpkgsで提供される最新リリースのNix本体を使う。
  nix.package = pkgs.nixVersions.latest;
  # nixコマンドと、flake.nixによる構成・依存管理を有効にする。
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 読み取った現在値。手動の上書きには lib.mkForce を使う。
  # Chromeは専用モジュールから保存データを読み込み、終了状態で復元する。
  # apps.nixでGUIアプリとコマンドも導入する。
  imports = [ ./captured-defaults.nix ./chrome.nix ./apps.nix ];
}
