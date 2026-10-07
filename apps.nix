{ lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "google-chrome" "chatgpt" "vscode" ];

  environment.systemPackages = [
    pkgs.google-chrome
    pkgs.chatgpt
    pkgs.codex
    pkgs.vscode
  ];
}
