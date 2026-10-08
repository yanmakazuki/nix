"""Terminalのプロファイルのフォントを変更し、色などの既存設定は保持する。"""
import argparse
import base64
import copy
from datetime import datetime, timezone
import json
from pathlib import Path
import plistlib
import subprocess

DOMAIN = 'com.apple.Terminal'
# 表示名ではなく、AppKitがフォントを検索するPostScript名を指定する。
FONT_NAME = 'HackNerdFontMono-Regular'
FONT_SIZE = 13


def font_archive(font_dir):
    """TerminalのFontキーで使う、NSFontのアーカイブデータを生成する。"""
    fonts = [str(p) for p in font_dir.rglob('*') if p.suffix.lower() in ('.ttf', '.otf')]
    if not fonts:
        raise RuntimeError(f'No fonts found in {font_dir}')
    # Nixストアのフォントをosascriptのプロセスに登録し、導入直後でも参照可能にする。
    # AppKitのNSKeyedArchiverを使い、Terminalと同じ形式でフォント情報を保存する。
    # Pythonとの受け渡しは、バイナリが壊れないようBase64にする。
    script = '''
ObjC.import("AppKit");
ObjC.import("CoreText");
const paths = FONT_PATHS;
paths.forEach(p => $.CTFontManagerRegisterFontsForURL($.NSURL.fileURLWithPath(p), 1, null));
const font = $.NSFont.fontWithNameSize(FONT_NAME, FONT_SIZE);
if (!font || font.isNil()) throw new Error("Hack Nerd Font Mono is unavailable");
$.NSKeyedArchiver.archivedDataWithRootObject(font).base64EncodedStringWithOptions(0).js;
'''.replace('FONT_PATHS', json.dumps(fonts)).replace('FONT_NAME', json.dumps(FONT_NAME)).replace('FONT_SIZE', str(FONT_SIZE))
    result = subprocess.run(['/usr/bin/osascript', '-l', 'JavaScript', '-'],
                            input=script, text=True, capture_output=True, check=True)
    return base64.b64decode(result.stdout.strip(), validate=True)


def update_preferences(original, font):
    """元データを変更せず、全プロファイルのFontだけを更新したコピーを返す。"""
    prefs = copy.deepcopy(original)
    profiles = prefs.setdefault('Window Settings', {})
    if not isinstance(profiles, dict) or any(not isinstance(p, dict) for p in profiles.values()):
        raise ValueError('Invalid Terminal profiles')
    if not profiles:
        profiles['Basic'] = {'name': 'Basic', 'type': 'Window Settings'}
    # 初回起動前などで設定が不足していても、標準・起動用のプロファイルを用意する。
    for key in ('Default Window Settings', 'Startup Window Settings'):
        name = prefs.setdefault(key, next(iter(profiles)))
        profiles.setdefault(name, {'name': name, 'type': 'Window Settings'})
    for profile in profiles.values():
        profile['Font'] = font
    return prefs


def setup(font_dir):
    """ユーザーのTerminal設定を読み込み、バックアップ後に変更を適用する。"""
    font = font_archive(font_dir)
    result = subprocess.run(['/usr/bin/defaults', 'export', DOMAIN, '-'], capture_output=True)
    if result.returncode:
        # 設定が未作成の場合だけ空の構成から始める。他の読み取りエラーは無視しない。
        if b'does not exist' not in result.stderr and b'not found' not in result.stderr:
            raise RuntimeError(result.stderr.decode(errors='replace'))
        original = {}
    else:
        original = plistlib.loads(result.stdout)
    prefs = update_preferences(original, font)
    if prefs == original:
        print('Terminal font is already configured.')
        return
    # defaultsが管理する設定を上書きする前に、元のplistをユーザー専用で保存する。
    backup_dir = Path.home() / 'Library/Application Support/nix-settings/terminal-backups'
    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
    backup = backup_dir / f'{DOMAIN}-{stamp}.plist'
    backup.write_bytes(plistlib.dumps(original))
    backup.chmod(0o600)
    # plistファイルへの直接書き込みを避け、macOSの設定管理を通して反映する。
    subprocess.run(['/usr/bin/defaults', 'import', DOMAIN, '-'],
                   input=plistlib.dumps(prefs), check=True)
    print(f'Terminal: {FONT_NAME} {FONT_SIZE}pt. Backup: {backup}')
    print('Quit and reopen Terminal to use the updated font.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--font-dir', type=Path, required=True)
    setup(parser.parse_args().font_dir)
