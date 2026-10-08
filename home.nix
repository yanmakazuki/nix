{ pkgs, ... }:
{
  # Home Managerの互換性基準。パッケージ更新時にこの値を変更する必要はない。
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.codex
    pkgs.nodejs # npm・npxも同梱する。
    pkgs.rustc
    pkgs.cargo
    pkgs.rust-analyzer
    pkgs.rustfmt
    pkgs.clippy
    pkgs.git
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.lazygit
    pkgs.tree-sitter
    pkgs.curl
  ];

  xdg.enable = true;
  programs.neovim = {
    enable = true;
    initLua = builtins.readFile ./nvim/init.lua;
  };

  # ファイル単位で管理し、LazyVimが生成するlazy-lock.jsonの保存先は書き込み可能に保つ。
  xdg.configFile."nvim/lua/config/lazy.lua".source = ./nvim/lua/config/lazy.lua;
}
