{ config, lib, pkgs, ... }:
let
  snapshot = pkgs.writeText "chrome-settings.json"
    (builtins.toJSON (import ./captured-chrome.nix));

  restoreChrome = pkgs.writeShellApplication {
    name = "restore-chrome-settings";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./scripts/restore_chrome_settings.py} \
        --snapshot ${snapshot} "$@"
    '';
  };

  runAsUser = "/usr/bin/sudo -H -u ${lib.escapeShellArg config.system.primaryUser} -- ${restoreChrome}/bin/restore-chrome-settings";
in
{
  environment.systemPackages = [ restoreChrome ];

  system.activationScripts.preActivation.text = lib.mkBefore ''
    ${runAsUser} --check-closed
  '';

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${runAsUser}
  '';
}
