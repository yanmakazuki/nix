# defaultsから読み取った保存値。取り込みスクリプトで生成。
{ ... }:
{
  # macOSのユーザー設定を宣言する。
  system.defaults = {
    # Dockの表示、操作、固定項目。
    "dock" = {
      # Dockを自動的に隠す。
      "autohide" = true;
      # Mission Controlで同じアプリのウィンドウをまとめる。
      "expose-group-apps" = true;
      # ポインターを重ねたDockアイコンを拡大する。
      "magnification" = true;
      # 最小化したウィンドウをアプリのDockアイコンに収める。
      "minimize-to-application" = true;
      # 起動中のアプリをDockのインジケーターで示す。
      "show-process-indicators" = true;
      # 最近使ったアプリをDockに表示する。
      "show-recents" = false;
      # 指を広げるジェスチャーによるデスクトップ表示を有効にする。
      "showDesktopGestureEnabled" = false;
      # Dockアイコンの通常サイズ。
      "tilesize" = 50;
      # Dockアイコンを拡大したときのサイズ。
      "largesize" = 100;
      # 右下のホットコーナーの動作。1は無効。
      "wvous-br-corner" = 1;
      # Dockに固定するアプリなどの並び順。アプリ本体はインストールしない。
      "persistent-apps" = [
        {
          # Dockに固定するアプリの絶対パス。
          "app" = "/Applications/Google Chrome.app";
        }
        {
          # Dockに固定するアプリの絶対パス。
          "app" = "/System/Applications/Utilities/Terminal.app";
        }
        {
          # Dockに固定するアプリの絶対パス。
          "app" = "/Applications/ChatGPT.app";
        }
        {
          # Dockに固定するアプリの絶対パス。
          "app" = "/System/Applications/Apps.app";
        }
      ];
      # Dockのファイル・フォルダー側の固定項目。空リストは固定項目なし。
      "persistent-others" = [ ];
    };
    # Finderの表示と新規ウィンドウの設定。
    "finder" = {
      # 外付けディスクをデスクトップに表示する。
      "ShowExternalHardDrivesOnDesktop" = true;
      # 内蔵ディスクをデスクトップに表示する。
      "ShowHardDrivesOnDesktop" = false;
      # 取り外し可能なメディアをデスクトップに表示する。
      "ShowRemovableMediaOnDesktop" = true;
      # Finderの既定表示形式。Nlsvはリスト表示。
      "FXPreferredViewStyle" = "Nlsv";
      # 新しいFinderウィンドウで開く場所。Homeはホームフォルダー。
      "NewWindowTarget" = "Home";
    };
    # macOS全体で使う表示・入力・操作の設定。
    "NSGlobalDomain" = {
      # スワイプで前後のページへ移動する。
      "AppleEnableSwipeNavigateWithScrolls" = true;
      # 対応する入力欄で自動的に大文字にする。
      "NSAutomaticCapitalizationEnabled" = false;
      # スペースを2回入力したときにピリオドを挿入する。
      "NSAutomaticPeriodSubstitutionEnabled" = false;
      # メニューバーを自動的に隠す。
      "_HIHideMenuBar" = false;
      # ドラッグ中に重ねたフォルダーを自動的に開く。
      "com.apple.springing.enabled" = true;
      # トラックパッドの強めのクリックを有効にする。
      "com.apple.trackpad.forceClick" = true;
      # キーを押し続けたときの繰り返し間隔。値が小さいほど速い。
      "KeyRepeat" = 2;
      # キーの繰り返しが始まるまでの待ち時間。値が小さいほど短い。
      "InitialKeyRepeat" = 15;
      # ドラッグ中にフォルダーが開くまでの待ち時間。
      "com.apple.springing.delay" = 0.5;
      # トラックパッドのポインター移動速度。
      "com.apple.trackpad.scaling" = 2.0;
      # macOSの外観。Darkはダークモード。
      "AppleInterfaceStyle" = "Dark";
      # アイコンとウィジェットの外観。RegularDarkは通常のダーク表示。
      "AppleIconAppearanceTheme" = "RegularDark";
      # 新しい書類をタブで開く方針。alwaysは常にタブを優先。
      "AppleWindowTabbingMode" = "always";
    };
    # 内蔵トラックパッドのクリックとジェスチャー。
    "trackpad" = {
      # タップでクリックする。
      "Clicking" = true;
      # タップ操作によるドラッグを有効にする。
      "Dragging" = true;
      # ドラッグロックを有効にする。
      "DragLock" = false;
      # トラックパッドの触覚フィードバックを有効にする。
      "ActuateDetents" = true;
      # 強めのクリックを抑制する。falseは抑制しない。
      "ForceSuppressed" = false;
      # 2本指による副ボタンクリックを有効にする。
      "TrackpadRightClick" = true;
      # 3本指ドラッグを有効にする。
      "TrackpadThreeFingerDrag" = false;
      # 指を離した後も慣性でスクロールする。
      "TrackpadMomentumScroll" = true;
      # ピンチによる拡大・縮小を有効にする。
      "TrackpadPinch" = true;
      # 2本指による回転ジェスチャーを有効にする。
      "TrackpadRotate" = true;
      # 2本指のダブルタップによるスマートズームを有効にする。
      "TrackpadTwoFingerDoubleTapGesture" = false;
      # 通常クリックに必要な押し込みの強さ。0は弱い、1は中、2は強い。
      "FirstClickThreshold" = 1;
      # 強めのクリックに必要な押し込みの強さ。0は弱い、1は中、2は強い。
      "SecondClickThreshold" = 1;
      # 隅での副ボタンクリック。0は無効、1は左下、2は右下。
      "TrackpadCornerSecondaryClick" = 0;
      # 4本指の左右スワイプ。0は無効、2は全画面アプリ間の移動。
      "TrackpadFourFingerHorizSwipeGesture" = 2;
      # 4本指の上下スワイプ。0は無効、2はMission Controlなどの表示。
      "TrackpadFourFingerVertSwipeGesture" = 2;
      # 4本指のピンチ・指を広げる操作。0は無効、2は有効。
      "TrackpadFourFingerPinchGesture" = 0;
      # 3本指の左右スワイプの動作（macOS内部値）。
      "TrackpadThreeFingerHorizSwipeGesture" = 1;
      # 3本指の上下スワイプ。0は無効、2はMission Controlなどの表示。
      "TrackpadThreeFingerVertSwipeGesture" = 2;
      # 3本指タップによる調べる操作。0は無効、2は有効。
      "TrackpadThreeFingerTapGesture" = 0;
    };
    # Stage Manager、ウィジェット、ウィンドウのタイル配置。
    "WindowManager" = {
      # Stage Managerの最近使ったアプリの一覧を自動的に隠す。
      "AutoHide" = true;
      # Stage Managerで同じアプリのウィンドウをまとめて表示する。
      "AppWindowGroupingBehavior" = true;
      # Stage Manager使用中にデスクトップ上の項目を隠す。
      "HideDesktop" = true;
      # Optionキーを使ったウィンドウのタイル配置を有効にする。
      "EnableTilingOptionAccelerator" = false;
      # タイル配置したウィンドウの間に余白を設ける。
      "EnableTiledWindowMargins" = false;
      # 通常のデスクトップでウィジェットを隠す。
      "StandardHideWidgets" = true;
      # Stage Manager使用中にウィジェットを隠す。
      "StageManagerHideWidgets" = true;
    };
    # 専用オプションがない設定をmacOSのキー名で指定。
    "CustomUserPreferences" = {
      # macOS全体で使う表示・入力・操作の設定。
      "NSGlobalDomain" = {
        # 優先言語の順序。先頭の言語を優先する。
        "AppleLanguages" = [
          "en-JP"
          "ja-JP"
        ];
        # 地域と書式のロケール。en_JPは英語・日本の地域設定。
        "AppleLocale" = "en_JP";
        # フルスクリーン時もメニューバーを表示する。
        "AppleMenuBarVisibleInFullscreen" = true;
      };
      # メニューバーの時計表示。
      "com.apple.menuextra.clock" = {
        # 時計にAM・PMを表示する。
        "ShowAMPM" = true;
        # 時計の日付表示の方針（macOS内部値）。
        "ShowDate" = 1;
        # 時計に曜日を表示する。
        "ShowDayOfWeek" = false;
      };
      # コントロールセンターとメニューバーの表示設定。
      "com.apple.controlcenter" = {
        # メニューバーの自動非表示の方針（macOS内部値）。
        "AutoHideMenuBarOption" = 3;
        # メニューバーのバッテリー項目の表示状態。
        "NSStatusItem VisibleCC Battery" = true;
        # メニューバーのディスプレイ項目の表示状態。
        "NSStatusItem VisibleCC Display" = true;
        # メニューバーのサウンド項目の表示状態。
        "NSStatusItem VisibleCC Sound" = true;
        # メニューバーのWi-Fi項目の表示状態。
        "NSStatusItem VisibleCC WiFi" = true;
      };
      # キーボードと入力切り替えの設定。
      "com.apple.HIToolbox" = {
        # Fn・地球儀キーを押したときの動作（macOS内部値）。
        "AppleFnUsageType" = 1;
        # Caps Lockキーの長押しによるオフ切り替えの設定。
        "AppleCapsLockPressAndHoldToggleOff" = false;
      };
    };
  };
}
