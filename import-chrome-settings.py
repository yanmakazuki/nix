"""Read selected Chrome preferences into Nix data without modifying Chrome."""
import argparse
import datetime
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PATHS = '''
browser.enable_spellchecking browser.show_home_button
browser.theme.color_scheme2 browser.theme.is_grayscale2
bookmark_bar.show_on_all_tabs homepage homepage_is_newtabpage
session.restore_on_startup session.startup_urls
intl.accept_languages intl.selected_languages
download.default_directory download.prompt_for_download download.directory_upgrade
credentials_enable_service profile.password_manager_enabled
profile.password_manager_leak_detection autofill.profile_enabled autofill.credit_card_enabled
autofill.payment_methods_mandatory_reauth
webkit.webprefs.tabs_to_links webkit.webprefs.default_font_size
webkit.webprefs.default_fixed_font_size webkit.webprefs.minimum_font_size
webkit.webprefs.standard_font_family webkit.webprefs.fixed_font_family
webkit.webprefs.serif_font_family webkit.webprefs.sansserif_font_family
webkit.webprefs.javascript_enabled webkit.webprefs.loads_images_automatically
translate.enabled translate_blocked_languages
spellcheck.dictionaries spellcheck.use_spelling_service
safebrowsing.enabled safebrowsing.enhanced search.suggest_enabled
net.network_prediction_options alternate_error_pages.enabled
privacy_sandbox.m1.topics_enabled privacy_sandbox.m1.fledge_enabled
privacy_sandbox.m1.ad_measurement_enabled
profile.block_third_party_cookies profile.cookie_controls_mode
profile.content_settings.enable_quiet_permission_ui
profile.default_zoom_level default_zoom_level
extensions.pinned_extensions extensions.theme.id
accessibility.captions settings.force_google_safesearch
printing.print_preview_sticky_settings.appState
'''.split()
CONTENT_TYPES = set('''
notifications geolocation cookies popups images javascript sound ads
ar vr background_sync captured_surface_control file_system_write_guard
hid_guard idle_detection local_network midi_sysex payment_handler sensors
serial_guard usb_guard web_app_installation automatic_downloads
media_stream_camera media_stream_mic clipboard_read_write window_management
'''.split())
SEARCH_KEYS = ['short_name', 'keyword', 'url', 'suggestions_url',
               'search_url_post_params', 'suggestions_url_post_params', 'input_encodings']
POLICIES = {
    'profile.default_content_setting_values.notifications': 'DefaultNotificationsSetting',
    'profile.default_content_setting_values.sensors': 'DefaultSensorsSetting',
    'profile.default_content_setting_values.usb_guard': 'DefaultWebUsbGuardSetting',
    'browser.enable_spellchecking': 'SpellcheckEnabled',
}

def get(data, path):
    for part in path.split('.'):
        if not isinstance(data, dict) or part not in data:
            return None, False
        data = data[part]
    return data, True


def quoted(value):
    return json.dumps(value, ensure_ascii=False).replace('${', '\\${')


def nix(value, depth=0):
    pad = '  ' * depth
    if value is None:
        return 'null'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, str):
        return quoted(value)
    if isinstance(value, (int, float)):
        if value != value or value in (float('inf'), float('-inf')):
            raise ValueError('Non-finite number')
        return repr(value)
    if isinstance(value, list):
        return '[\n' + ''.join(pad + '  ' + nix(v, depth + 1) + '\n' for v in value) + pad + ']'
    if isinstance(value, dict):
        return '{\n' + ''.join(pad + '  ' + quoted(k) + ' = ' + nix(v, depth + 1) + ';\n' for k, v in value.items()) + pad + '}'
    raise TypeError(type(value).__name__)


def capture(base):
    profiles = {}
    absent = {}
    for pref in sorted(base.glob('*/Preferences')):
        if pref.parent.name != 'Default' and not pref.parent.name.startswith('Profile '):
            continue
        data = json.loads(pref.read_text())
        selected = {}
        missing = []
        for key in PATHS:
            val, found = get(data, key)
            if found:
                selected[key] = val
            else:
                missing.append(key)
        defaults, _ = get(data, 'profile.default_content_setting_values')
        for key, val in (defaults or {}).items():
            if key in CONTENT_TYPES:
                selected['profile.default_content_setting_values.' + key] = val
        # Only user permission settings; exclude engagement, visits and runtime telemetry.
        exceptions, _ = get(data, 'profile.content_settings.exceptions')
        site_permissions = {}
        for kind, entries in (exceptions or {}).items():
            if kind not in CONTENT_TYPES or not isinstance(entries, dict):
                continue
            settings = {origin: {'setting': value['setting']} for origin, value in entries.items()
                        if isinstance(value, dict) and 'setting' in value
                        and isinstance(value['setting'], (bool, int, str))}
            if settings:
                site_permissions[kind] = settings
        engine, _ = get(data, 'default_search_provider_data.mirrored_template_url_data')
        search = {key: engine[key] for key in SEARCH_KEYS if engine and key in engine}
        # Secure Preferences is read only for extension metadata, never for protected secrets.
        secure = pref.parent / 'Secure Preferences'
        secure_data = json.loads(secure.read_text()) if secure.exists() else {}
        installed, _ = get(secure_data, 'extensions.settings')
        if not installed:
            installed, _ = get(data, 'extensions.settings')
        extensions = []
        for identifier, item in (installed or {}).items():
            manifest = item.get('manifest', {})
            extension = {'id': identifier, 'name': manifest.get('name'),
                         'version': manifest.get('version'), 'location': item.get('location'),
                         'pinned': identifier in selected.get('extensions.pinned_extensions', [])}
            if 'state' in item:
                extension['state'] = item['state']
            extensions.append(extension)
        candidates = {policy: selected[path] for path, policy in POLICIES.items() if path in selected}
        profiles[pref.parent.name] = {'preferences': selected, 'sitePermissions': site_permissions,
                                      'searchProvider': search, 'extensions': extensions,
                                      'policyCandidates': candidates}
        absent[pref.parent.name] = missing
    if not profiles:
        raise RuntimeError('No Chrome profiles found; existing output preserved')
    return profiles, absent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--user-data-dir', type=Path,
                        default=Path.home() / 'Library/Application Support/Google/Chrome')
    args = parser.parse_args()
    profiles, absent = capture(args.user_data_dir)
    # Serialize both outputs before replacing either file.
    text = ('# Chromeの保存設定。データのスナップショットであり、nix-darwinモジュールではない。\n'
            '# policyCandidatesも参照用。Chromeへの適用は行わない。\n'
            + nix({'profiles': profiles}) + '\n')
    count = sum(len(p['preferences']) for p in profiles.values())
    extension_count = sum(len(p['extensions']) for p in profiles.values())
    report = {'capturedAt': datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).isoformat(),
              'preferenceCount': count, 'extensionCount': extension_count,
              'profiles': profiles, 'notStored': absent,
              'notes': ['明示的な候補項目のみ。未保存の標準値は推測しない。',
                        'パスワード、Cookie、履歴、ログイン情報、拡張機能の内部データは取り込まない。',
                        '検索URLはChrome内部のテンプレート形式。ポリシーへ自動変換しない。',
                        'BookmarkBarEnabled=falseは常時表示オフと同義ではないため変換しない。',
                        'policyCandidatesは適用未検証で、macOSのdefaults経由では無視される場合がある。']}
    report_text = json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + '\n'
    for name, content in [('captured-chrome.nix', text), ('chrome-capture-report.json', report_text)]:
        temp = ROOT / (name + '.tmp')
        temp.write_text(content)
        temp.replace(ROOT / name)
    print(f'Captured {len(profiles)} profiles, {count} preferences, {extension_count} extension records; no Chrome changes.')


if __name__ == '__main__':
    main()
