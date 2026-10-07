{ lib, pkgs, ... }:
{
  # Chrome・ChatGPT・VS Codeの非自由ライセンスを、対象の3パッケージに限って許可する。
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "google-chrome" "chatgpt" "vscode" ];

  # Nixpkgsから導入するGUIアプリとCUIコマンド。
  # GUIはnix-darwinによって /Applications/Nix Apps に配置される。
  environment.systemPackages = [
    # Google ChromeのGUIのみ。
    google-chrome
    # ChatGPTのmacOS GUI。ログインは初回起動後に行う。
    pkgs.chatgpt
    # OpenAIのCUIツールCodex CLI。codexコマンドを導入する。
    pkgs.codex
    # VS CodeのGUIと、同梱のcodeコマンドを導入する。
    pkgs.vscode
  ];
}
