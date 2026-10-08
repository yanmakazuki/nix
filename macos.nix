{ config, lib, pkgs, ... }:
let
  setupTerminalFont = pkgs.writeShellApplication {
    name = "setup-terminal-font";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./scripts/setup_terminal_font.py} --font-dir ${pkgs.nerd-fonts.hack}
    '';
  };
in
{
  fonts.packages = [ pkgs.nerd-fonts.hack ];
  environment.systemPackages = [ setupTerminalFont ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/sudo -H -u ${lib.escapeShellArg config.system.primaryUser} -- ${setupTerminalFont}/bin/setup-terminal-font
  '';

  system.defaults = {
    "dock" = {
      "autohide" = true;
      "expose-group-apps" = true;
      "magnification" = true;
      "minimize-to-application" = true;
      "show-process-indicators" = true;
      "show-recents" = false;
      "showDesktopGestureEnabled" = false;
      "tilesize" = 50;
      "largesize" = 100;
      "wvous-br-corner" = 1;
      "persistent-apps" = [
        {
          "app" = "/Applications/Nix Apps/Google Chrome.app";
        }
        {
          "app" = "/System/Applications/Utilities/Terminal.app";
        }
        {
          "app" = "/Applications/Nix Apps/ChatGPT.app";
        }
        {
          "app" = "/System/Applications/Apps.app";
        }
      ];
      "persistent-others" = [ ];
    };
    "finder" = {
      "ShowExternalHardDrivesOnDesktop" = true;
      "ShowHardDrivesOnDesktop" = false;
      "ShowRemovableMediaOnDesktop" = true;
      "FXPreferredViewStyle" = "Nlsv";
      "NewWindowTarget" = "Home";
    };
    "NSGlobalDomain" = {
      "AppleEnableSwipeNavigateWithScrolls" = true;
      "NSAutomaticCapitalizationEnabled" = false;
      "NSAutomaticPeriodSubstitutionEnabled" = false;
      "_HIHideMenuBar" = false;
      "com.apple.springing.enabled" = true;
      "com.apple.trackpad.forceClick" = true;
      "KeyRepeat" = 2;
      "InitialKeyRepeat" = 15;
      "com.apple.springing.delay" = 0.5;
      "com.apple.trackpad.scaling" = 2.0;
      "AppleInterfaceStyle" = "Dark";
      "AppleIconAppearanceTheme" = "RegularDark";
      "AppleWindowTabbingMode" = "always";
    };
    "trackpad" = {
      "Clicking" = true;
      "Dragging" = true;
      "DragLock" = false;
      "ActuateDetents" = true;
      "ForceSuppressed" = false;
      "TrackpadRightClick" = true;
      "TrackpadThreeFingerDrag" = false;
      "TrackpadMomentumScroll" = true;
      "TrackpadPinch" = true;
      "TrackpadRotate" = true;
      "TrackpadTwoFingerDoubleTapGesture" = false;
      "FirstClickThreshold" = 1;
      "SecondClickThreshold" = 1;
      "TrackpadCornerSecondaryClick" = 0;
      "TrackpadFourFingerHorizSwipeGesture" = 2;
      "TrackpadFourFingerVertSwipeGesture" = 2;
      "TrackpadFourFingerPinchGesture" = 0;
      "TrackpadThreeFingerHorizSwipeGesture" = 1;
      "TrackpadThreeFingerVertSwipeGesture" = 2;
      "TrackpadThreeFingerTapGesture" = 0;
    };
    "WindowManager" = {
      "AutoHide" = true;
      "AppWindowGroupingBehavior" = true;
      "HideDesktop" = true;
      "EnableTilingOptionAccelerator" = false;
      "EnableTiledWindowMargins" = false;
      "StandardHideWidgets" = true;
      "StageManagerHideWidgets" = true;
    };
    "CustomUserPreferences" = {
      "NSGlobalDomain" = {
        "AppleLanguages" = [
          "en-JP"
          "ja-JP"
        ];
        "AppleLocale" = "en_JP";
        "AppleMenuBarVisibleInFullscreen" = true;
      };
      "com.apple.menuextra.clock" = {
        "ShowAMPM" = true;
        "ShowDate" = 1;
        "ShowDayOfWeek" = false;
      };
      "com.apple.controlcenter" = {
        "AutoHideMenuBarOption" = 3;
        "NSStatusItem VisibleCC Battery" = true;
        "NSStatusItem VisibleCC Display" = true;
        "NSStatusItem VisibleCC Sound" = true;
        "NSStatusItem VisibleCC WiFi" = true;
      };
      "com.apple.HIToolbox" = {
        "AppleFnUsageType" = 1;
        "AppleCapsLockPressAndHoldToggleOff" = false;
      };
    };
  };
}
