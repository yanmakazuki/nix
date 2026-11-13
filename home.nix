{ pkgs, ... }:
let
  yaziChooserFile = "/tmp/helix-yazi-$PPID";
  yaziPickerScript = pkgs.writeShellScript "helix-yazi-picker" ''
    trap 'printf "\033[?1049h\033[?2004h" > /dev/tty' EXIT
    : > "$2"
    ${pkgs.yazi}/bin/yazi "$1" --chooser-file="$2"
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

  home.packages = with pkgs; [
    nodejs
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    pyright
    git
    gh
    lazygit
    opencode
    openbot
    yazi
  ];

  # ローカルLLMサーバー(127.0.0.1:11434)。launchdエージェントとして常駐する
  services.ollama.enable = true;

  xdg.configFile."ghostty/config".text = ''
    theme = TokyoNight Night
    background-opacity = 0.8
  '';

  programs.helix = {
    enable = true;
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
