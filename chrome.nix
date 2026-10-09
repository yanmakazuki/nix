{ config, lib, pkgs, ... }:
let
  chromeSettings = {
    "profiles" = {
      "Default" = {
        "preferences" = {
          "browser.theme.color_scheme2" = 2;
          "bookmark_bar.show_on_all_tabs" = false;
          "intl.selected_languages" = "en-US,en";
          "autofill.payment_methods_mandatory_reauth" = true;
          "spellcheck.dictionaries" = [
            "en-US"
          ];
          "net.network_prediction_options" = 0;
          "settings.force_google_safesearch" = false;
        } // lib.genAttrs
          (map (name: "profile.default_content_setting_values.${name}") [
            "ar"
            "background_sync"
            "file_system_write_guard"
            "hid_guard"
            "idle_detection"
            "local_network"
            "midi_sysex"
            "notifications"
            "payment_handler"
            "sensors"
            "serial_guard"
            "usb_guard"
            "vr"
            "web_app_installation"
          ])
          (_: 2);
      };
    };
  };

  snapshot = pkgs.writeText "chrome-settings.json"
    (builtins.toJSON chromeSettings);

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
