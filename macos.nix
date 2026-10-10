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
  security.pam.services.sudo_local.touchIdAuth = true;

  # -currentHostで読み取った設定は、Home Managerからホスト単位で書き込む。
  # 下のCustomUserPreferencesは通常のユーザー設定として書き込む。
  home-manager.users.${config.system.primaryUser}.targets.darwin.currentHostDefaults = {
    "com.apple.Spotlight".MenuItemHidden = true;
    "com.apple.controlcenter" = {
      # 8・2は現在のMacから読み取った内部値。表示フラグとは別に保持する。
      FocusModes = 8;
      NowPlaying = 8;
      ScreenMirroring = 8;
      Timer = 8;
      Weather = 2;
      WiFi = 8;
    };
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/sudo -H -u ${lib.escapeShellArg config.system.primaryUser} -- ${setupTerminalFont}/bin/setup-terminal-font
  '';

  # 現在の電源設定を再現する。画面スリープは電源種別で分ける。
  system.activationScripts.power.text = lib.mkAfter ''
    /usr/bin/pmset -a lowpowermode 1 sleep 1 disksleep 10 powernap 1
    /usr/bin/pmset -b displaysleep 2 lessbright 1
    /usr/bin/pmset -c displaysleep 10
  '';

  system.defaults = {
    CustomSystemPreferences = {
      # sudo defaultsで読み取ったrootユーザーのキーボード照明設定。
      "/var/root/Library/Preferences/com.apple.CoreBrightness".KeyboardBacklight = {
        KeyboardBacklightABEnabled = 1;
        KeyboardBacklightIdleDimTime = 60;
        KeyboardBacklightManualBrightness = 0.003;
        KeyboardBacklightMuted = 0;
        KeyboardBacklightPrefVersion = 1;
        KeyboardBacklightUserOffset = 0;
        # キーボードIDと学習済みの明るさ曲線は、このMacの値を保持する。
        "95158272" = {
          KeyboardBacklightAdjustedBrightnessCurve = {
            KeyboardCurveX1 = 0;
            KeyboardCurveX2 = 50;
            KeyboardCurveX3 = 150;
            KeyboardCurveX4 = 300;
            KeyboardCurveY1 = 0.05;
            KeyboardCurveY2 = 6.5;
            KeyboardCurveY3 = 10.0;
            KeyboardCurveY4 = 0.15;
          };
          KeyboardBacklightMaxUser = 15.0;
        };
      };
    };
    # VisibleCCの表示フラグに加え、標準オプションでメニューバーの表示モードも設定する。
    controlcenter = {
      Display = true;
      Sound = true;
    };
    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 1; # 日付を常に表示する。
      ShowDayOfWeek = false;
    };
    dock = {
      autohide = true;
      expose-group-apps = true;
      magnification = true;
      minimize-to-application = true;
      show-process-indicators = true;
      show-recents = false;
      showDesktopGestureEnabled = false;
      tilesize = 50;
      largesize = 100;
      wvous-br-corner = 1;
      persistent-apps = [
        { app = "/Applications/Nix Apps/Google Chrome.app"; }
        { app = "/System/Applications/Utilities/Terminal.app"; }
        { app = "/Applications/Nix Apps/ChatGPT.app"; }
        { app = "/System/Applications/Apps.app"; }
      ];
      persistent-others = [ ];
    };
    finder = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Home";
    };
    NSGlobalDomain = {
      AppleEnableSwipeNavigateWithScrolls = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      _HIHideMenuBar = false;
      "com.apple.springing.enabled" = true;
      "com.apple.trackpad.forceClick" = true;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.springing.delay" = 0.5;
      "com.apple.trackpad.scaling" = 2.0;
      AppleInterfaceStyle = "Dark";
      AppleIconAppearanceTheme = "RegularDark";
      AppleWindowTabbingMode = "always";
    };
    trackpad = {
      Clicking = true;
      Dragging = true;
      DragLock = false;
      ActuateDetents = true;
      ForceSuppressed = false;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
      TrackpadMomentumScroll = true;
      TrackpadPinch = true;
      TrackpadRotate = true;
      TrackpadTwoFingerDoubleTapGesture = false;
      FirstClickThreshold = 1;
      SecondClickThreshold = 1;
      TrackpadCornerSecondaryClick = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 0;
      TrackpadThreeFingerHorizSwipeGesture = 1;
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadThreeFingerTapGesture = 0;
    };
    WindowManager = {
      AutoHide = true;
      AppWindowGroupingBehavior = true;
      HideDesktop = true;
      EnableTilingOptionAccelerator = false;
      EnableTiledWindowMargins = false;
      StandardHideWidgets = true;
      StageManagerHideWidgets = true;
    };
    CustomUserPreferences = {
      "com.apple.dock" = {
        enterMissionControlByTopWindowDrag = false;
      };
      NSGlobalDomain = {
        AppleLanguages = [
          "en-JP"
          "ja-JP"
        ];
        AppleLocale = "en_JP";
        AppleMenuBarVisibleInFullscreen = true;
      };
      "com.apple.controlcenter" = {
        # 自動非表示の内部値を、現在のMacから読み取った状態で保持する。
        AutoHideMenuBarOption = 3;
        # 現在の配置値を保持する。BentoBox-0はコントロールセンター。
        "NSStatusItem Preferred Position Battery" = 194;
        "NSStatusItem Preferred Position BentoBox-0" = 104;
        "NSStatusItem Preferred Position Display" = 236;
        "NSStatusItem Preferred Position Sound" = 272;
        "NSStatusItem Preferred Position WiFi" = 220;
        # 各項目の表示フラグ。表示モードの設定と併せて管理する。
        "NSStatusItem VisibleCC Battery" = true;
        "NSStatusItem VisibleCC BentoBox-0" = true;
        "NSStatusItem VisibleCC Clock" = true;
        "NSStatusItem VisibleCC Display" = true;
        "NSStatusItem VisibleCC Sound" = true;
        "NSStatusItem VisibleCC WiFi" = true;
      };
      "com.apple.TextInputMenu".visible = false;
      "com.apple.Spotlight"."NSStatusItem VisibleCC Item-0" = false;
      "com.apple.HIToolbox" = {
        AppleFnUsageType = 1;
        AppleCapsLockPressAndHoldToggleOff = false;
      };
    };
  };
}
