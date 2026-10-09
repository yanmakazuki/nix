{ pkgs, ... }:
{
  # Home Managerの互換性基準。パッケージ更新時にこの値を変更する必要はない。
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.codex
    pkgs.nodejs
    pkgs.rustc
    pkgs.cargo
    pkgs.rust-analyzer
    pkgs.rustfmt
    pkgs.git
    pkgs.docker
    pkgs.lazygit
  ];

  # ログイン時にDocker用のLinux VMを起動する。
  services.colima = {
    enable = true;
    colimaHomeDir = ".colima";
    profiles.default = {
      isActive = true;
      isService = true;
      setDockerHost = false;
    };
  };

  xdg.enable = true;
  programs.helix = {
    enable = true;
    defaultEditor = true;
  };
}
