{ pkgs, ... }:
let
  yaziPicker = [
    '':insert-output : > "/tmp/helix-yazi-$PPID"; ${pkgs.yazi}/bin/yazi "%{buffer_name}" --chooser-file="/tmp/helix-yazi-$PPID"; printf "\033[?1049h\033[?2004h" > /dev/tty''
    '':vsplit "%sh{head -n 1 /tmp/helix-yazi-$PPID}"''
    ":redraw"
    ":set mouse false"
    ":set mouse true"
  ];
in
{
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.codex
    pkgs.nodejs
    pkgs.rustc
    pkgs.cargo
    pkgs.rustfmt
    pkgs.clippy
    pkgs.rust-analyzer
    pkgs.pyright
    pkgs.git
    pkgs.lazygit
    pkgs.yazi
  ];

  xdg.enable = true;
  xdg.configFile."ghostty/config".text = ''
    theme = TokyoNight Night
  '';

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
