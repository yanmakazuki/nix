{ config, lib, pkgs, ... }:
let
  chromeSettings = {
    "profiles" = {
      "Default" = {
        "preferences" = {
          "browser.enable_spellchecking" = true;
          "browser.theme.color_scheme2" = 2;
          "browser.theme.is_grayscale2" = true;
          "bookmark_bar.show_on_all_tabs" = false;
          "intl.selected_languages" = "en-US,en";
          "autofill.payment_methods_mandatory_reauth" = true;
          "webkit.webprefs.tabs_to_links" = false;
          "spellcheck.dictionaries" = [
            "en-US"
          ];
          "spellcheck.use_spelling_service" = true;
          "net.network_prediction_options" = 0;
          "profile.content_settings.enable_quiet_permission_ui" = {
            "geolocation" = true;
          };
          "extensions.theme.id" = "";
          "accessibility.captions" = {
            "headless_caption_enabled" = false;
          };
          "settings.force_google_safesearch" = false;
          "profile.default_content_setting_values.ar" = 2;
          "profile.default_content_setting_values.background_sync" = 2;
          "profile.default_content_setting_values.file_system_write_guard" = 2;
          "profile.default_content_setting_values.hid_guard" = 2;
          "profile.default_content_setting_values.idle_detection" = 2;
          "profile.default_content_setting_values.local_network" = 2;
          "profile.default_content_setting_values.midi_sysex" = 2;
          "profile.default_content_setting_values.notifications" = 2;
          "profile.default_content_setting_values.payment_handler" = 2;
          "profile.default_content_setting_values.sensors" = 2;
          "profile.default_content_setting_values.serial_guard" = 2;
          "profile.default_content_setting_values.usb_guard" = 2;
          "profile.default_content_setting_values.vr" = 2;
          "profile.default_content_setting_values.web_app_installation" = 2;
        };
        "policyCandidates" = {
          "DefaultNotificationsSetting" = 2;
          "DefaultSensorsSetting" = 2;
          "DefaultWebUsbGuardSetting" = 2;
          "SpellcheckEnabled" = true;
        };
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
