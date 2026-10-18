{ pkgs, ... }:
let
  yaziChooserFile = "/tmp/helix-yazi-$PPID";
  yaziPickerScript = pkgs.writeShellScript "helix-yazi-picker" ''
    buffer_name=$1
    chooser_file=$2

    trap 'printf "\033[?1049h\033[?2004h" > /dev/tty' EXIT
    : > "$chooser_file"
    ${pkgs.yazi}/bin/yazi "$buffer_name" --chooser-file="$chooser_file"
  '';
  yaziPicker = [
    '':insert-output ${yaziPickerScript} "%{buffer_name}" "${yaziChooserFile}"''
    '':vsplit "%sh{head -n 1 ${yaziChooserFile}}"''
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
    background-opacity = 0.8
    desktop-notifications = true
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
