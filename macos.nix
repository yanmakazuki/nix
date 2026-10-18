{ lib, ... }:
let
  menuBarVisibility = visible: items:
    lib.genAttrs (map (name: "NSStatusItem VisibleCC ${name}") items) (_: visible);
  menuBarItems = [ "Clock" "BentoBox-0" "Battery" ];
  hiddenMenuBarItems = [
    "AirDrop"
    "Bluetooth"
    "Display"
    "FocusModes"
    "NowPlaying"
    "Sound"
    "WiFi"
    "ScreenMirroring"
    "AccessibilityShortcuts"
    "UserSwitcher"
    "Spotlight"
    "Siri"
    "TimeMachine"
    "VPN"
  ];
in
{
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    CustomSystemPreferences = {
      "/var/root/Library/Preferences/com.apple.CoreBrightness".KeyboardBacklight = {
        KeyboardBacklightABEnabled = 1;
        KeyboardBacklightIdleDimTime = 60;
        KeyboardBacklightManualBrightness = 0.003;
        KeyboardBacklightMuted = 0;
        KeyboardBacklightPrefVersion = 1;
        KeyboardBacklightUserOffset = 0;
      };
    };
    controlcenter = {
      AirDrop = false;
      Bluetooth = false;
      Display = false;
      FocusModes = false;
      NowPlaying = false;
      Sound = false;
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
        { app = "/Applications/Nix Apps/Google Chrome.app"; }
        { app = "/Applications/Nix Apps/Ghostty.app"; }
        { app = "/System/Applications/Apps.app"; }
      ];
      persistent-others = [ ];
    };
    finder = {
      NewWindowTarget = "Home";
    };
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
    };
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleLanguages = [
          "en-JP"
          "ja-JP"
        ];
        AppleLocale = "en_JP";
        AppleMenuBarVisibleInFullscreen = true;
      };
      "com.apple.controlcenter" = menuBarVisibility true menuBarItems
        // menuBarVisibility false hiddenMenuBarItems
        // {
        AutoHideMenuBarOption = 3;
      };
      "com.apple.dock".enterMissionControlByTopWindowDrag = false;
      "com.apple.TextInputMenu".visible = false;
      "com.apple.HIToolbox" = {
        AppleFnUsageType = 1;
        AppleCapsLockPressAndHoldToggleOff = true;
      };
    };
  };
}
