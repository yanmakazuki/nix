{ config, ... }:
{
  security.pam.services.sudo_local.touchIdAuth = true;

  # AC接続中だけ蓋閉じスリープを無効化し、バッテリーに切り替わったら解除する
  launchd.daemons.clamshell-awake = {
    script = ''
      pmset -g pslog | while read -r line; do
        case "$line" in
          *"'AC Power'"*)
            pmset -a disablesleep 1
            caffeinate -u -t 2
            ;;
          *"'Battery Power'"*)
            pmset -a disablesleep 0
            ioreg -r -k AppleClamshellState -d 4 | grep -q '"AppleClamshellState" = Yes' && pmset sleepnow
            ;;
        esac
      done
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  system.defaults = {
    CustomSystemPreferences."/var/root/Library/Preferences/com.apple.CoreBrightness".KeyboardBacklight = {
      KeyboardBacklightABEnabled = 1;
      KeyboardBacklightIdleDimTime = 60;
      KeyboardBacklightManualBrightness = 0.003;
      KeyboardBacklightMuted = 0;
      KeyboardBacklightPrefVersion = 1;
      KeyboardBacklightUserOffset = 0;
    };
    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 1;
      ShowDayOfWeek = false;
    };
    dock = {
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      autohide = true;
      magnification = true;
      minimize-to-application = true;
      show-process-indicators = true;
      show-recents = false;
      tilesize = 50;
      largesize = 100;
      persistent-apps = [
        "/Applications/Nix Apps/Google Chrome.app"
        "/Applications/Nix Apps/Ghostty.app"
        "/Users/${config.system.primaryUser}/Applications/Home Manager Apps/OpenBot.app"
        "/System/Applications/Apps.app"
      ];
      persistent-others = [ ];
    };
    spaces.spans-displays = false;
    finder.NewWindowTarget = "Home";
    hitoolbox.AppleFnUsageType = "Change Input Source";
    NSGlobalDomain = {
      AppleEnableSwipeNavigateWithScrolls = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      _HIHideMenuBar = false;
      "com.apple.springing.enabled" = true;
      "com.apple.trackpad.forceClick" = true;
      AppleInterfaceStyle = "Dark";
      AppleIconAppearanceTheme = "RegularDark";
      AppleWindowTabbingMode = "always";
    };
    trackpad = {
      Clicking = true;
      Dragging = true;
      ActuateDetents = true;
      ForceSuppressed = false;
      TrackpadRightClick = true;
      TrackpadMomentumScroll = true;
      TrackpadPinch = true;
      TrackpadThreeFingerVertSwipeGesture = 2;
    };
    WindowManager = {
      AutoHide = true;
      StandardHideWidgets = true;
      StandardHideDesktopIcons = true;
      HideDesktop = true;
    };
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleLanguages = [ "en-JP" "ja-JP" ];
        AppleLocale = "en_JP";
        AppleMenuBarVisibleInFullscreen = true;
      };
      "com.apple.controlcenter".AutoHideMenuBarOption = 3;
      "com.apple.dock".enterMissionControlByTopWindowDrag = false;
      "com.apple.HIToolbox".AppleCapsLockPressAndHoldToggleOff = true;
    };
  };
}
