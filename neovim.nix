{ config, lib, pkgs, ... }:
let
  setupLazyvim = pkgs.writeShellApplication {
    name = "setup-lazyvim";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./scripts/setup_lazyvim.py} --source ${./nvim}
    '';
  };
in
{
  environment.systemPackages = [
    pkgs.neovim
    pkgs.git
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.lazygit
    pkgs.tree-sitter
    pkgs.curl
    setupLazyvim
  ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/sudo -H -u ${lib.escapeShellArg config.system.primaryUser} -- ${setupLazyvim}/bin/setup-lazyvim
  '';
}
