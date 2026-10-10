{ pkgs, ... }:
let
  # 各Helixプロセスで選択結果を分け、空白を含むパスも開けるようにする。
  yaziPicker = [
    # :shは非同期なので、選択結果の初期化と端末の復元も同期実行する。
    '':insert-output : > "/tmp/helix-yazi-$PPID"; ${pkgs.yazi}/bin/yazi "%{buffer_name}" --chooser-file="/tmp/helix-yazi-$PPID"; printf "\033[?1049h\033[?2004h" > /dev/tty''
    # 展開結果の引用符は再解析されないため、:vsplit側でパス全体を囲む。
    '':vsplit "%sh{head -n 1 /tmp/helix-yazi-$PPID}"''
    ":redraw"
    ":set mouse false"
    ":set mouse true"
  ];
in
{
  # Home Managerの互換性基準。パッケージ更新時にこの値を変更する必要はない。
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.codex
    pkgs.nodejs
    pkgs.rustc
    pkgs.cargo
    pkgs.rust-analyzer
    pkgs.pyright
    pkgs.git
    pkgs.lazygit
    pkgs.yazi
  ];

  xdg.enable = true;
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "tokyonight";
      editor.line-number = "relative";
      keys.normal.space = {
        e = yaziPicker;
        E = yaziPicker;
      };
    };
  };
}
