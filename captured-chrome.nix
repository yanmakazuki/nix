# Chromeの保存設定。データのスナップショットであり、nix-darwinモジュールではない。
# policyCandidatesも参照用。Chromeへの適用は行わない。
{
  # Chromeプロファイルごとに読み取った設定。
  "profiles" = {
    # ChromeのDefaultプロファイル。
    "Default" = {
      # Chrome内部の保存設定。これだけではChromeへ適用されない。
      "preferences" = {
        # スペルチェックを有効にする。
        "browser.enable_spellchecking" = true;
        # テーマの配色モード（Chrome内部値）。
        "browser.theme.color_scheme2" = 2;
        # テーマのグレースケール設定。
        "browser.theme.is_grayscale2" = true;
        # すべてのタブでブックマークバーを常時表示する。
        "bookmark_bar.show_on_all_tabs" = false;
        # Chromeで選択した言語の一覧。
        "intl.selected_languages" = "en-US,en";
        # 支払い方法の自動入力で再認証を要求する。
        "autofill.payment_methods_mandatory_reauth" = true;
        # Tabキーのフォーカス移動にリンクを含める。
        "webkit.webprefs.tabs_to_links" = false;
        # スペルチェックで使用する辞書の言語。
        "spellcheck.dictionaries" = [
          "en-US"
        ];
        # オンラインのスペルチェックサービスを使う。
        "spellcheck.use_spelling_service" = true;
        # ネットワーク予測・プリロードの方針（Chrome内部値）。
        "net.network_prediction_options" = 0;
        # 権限確認で控えめな通知UIを使う種類。
        "profile.content_settings.enable_quiet_permission_ui" = {
          # 位置情報についての設定。
          "geolocation" = true;
        };
        # Chromeテーマの拡張機能ID。空文字はテーマ拡張機能の指定なし。
        "extensions.theme.id" = "";
        # 字幕のアクセシビリティ設定。
        "accessibility.captions" = {
          # Chrome内部の字幕機能の有効状態。
          "headless_caption_enabled" = false;
        };
        # Google検索のセーフサーチを強制する。
        "settings.force_google_safesearch" = false;
        # AR（拡張現実）の既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.ar" = 2;
        # バックグラウンド同期の既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.background_sync" = 2;
        # ファイルへの書き込みの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.file_system_write_guard" = 2;
        # HIDデバイスへのアクセスの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.hid_guard" = 2;
        # 端末のアイドル状態の検出の既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.idle_detection" = 2;
        # ローカルネットワークへのアクセスの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.local_network" = 2;
        # MIDI SysExメッセージの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.midi_sysex" = 2;
        # サイト通知の既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.notifications" = 2;
        # 支払いハンドラーの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.payment_handler" = 2;
        # 端末センサーへのアクセスの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.sensors" = 2;
        # シリアルポートへのアクセスの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.serial_guard" = 2;
        # USBデバイスへのアクセスの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.usb_guard" = 2;
        # VR（仮想現実）の既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.vr" = 2;
        # Webアプリのインストールの既定権限。0は既定、1は許可、2はブロック、3は確認（対応する種類のみ）。
        "profile.default_content_setting_values.web_app_installation" = 2;
      };
      # 管理ポリシーへの変換候補。参照用で、自動適用しない。
      "policyCandidates" = {
        # 通知の既定ポリシー候補。1は許可、2はブロック、3は確認。
        "DefaultNotificationsSetting" = 2;
        # センサーの既定ポリシー候補。2はブロック。
        "DefaultSensorsSetting" = 2;
        # WebUSBの既定ポリシー候補。2はブロック、3は確認。
        "DefaultWebUsbGuardSetting" = 2;
        # スペルチェックの有効化ポリシー候補。
        "SpellcheckEnabled" = true;
      };
    };
  };
}
