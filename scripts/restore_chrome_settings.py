"""Chromeが終了していることを確認し、保存済み設定を既存プロファイルにマージする。"""
import argparse
import copy
import datetime
import json
import os
from pathlib import Path
import pwd
import re
import subprocess
import sys
import tempfile

# Chrome側の整合性保護やアカウントに関わる設定は、自動復元の対象から除外する。
PROTECTED = ('extensions.', 'default_search_provider', 'protection.',
             'google.services.', 'account_values.')
PROTECTED_EXACT = {'homepage', 'homepage_is_newtabpage', 'browser.show_home_button',
                   'session.restore_on_startup', 'session.startup_urls', 'pinned_tabs'}


def chrome_is_running():
    """実行ユーザーのChrome本体・関連プロセスが起動しているか確認する。"""
    result = subprocess.run(['/bin/ps', '-U', str(os.getuid()), '-o', 'comm='],
                            check=True, capture_output=True, text=True)
    return any('/Google Chrome.app/Contents/' in line or
               line.strip() == 'Google Chrome' for line in result.stdout.splitlines())


def require_closed():
    if chrome_is_running():
        raise RuntimeError('Chromeを完全に終了してから再実行してください。設定は書き込みません。')


def merge_dict(target, updates):
    """入れ子の辞書をマージし、復元データに含まれない既存キーは残す。"""
    for key, value in updates.items():
        if isinstance(value, dict) and isinstance(target.get(key), dict):
            merge_dict(target[key], value)
        else:
            target[key] = copy.deepcopy(value)


def set_preference(target, path, value):
    """ドット区切りの設定キーを、ChromeのJSONの階層に展開して設定する。"""
    parts = path.split('.')
    if not all(parts):
        raise ValueError(f'Invalid preference path: {path}')
    node = target
    for part in parts[:-1]:
        if part not in node:
            node[part] = {}
        if not isinstance(node[part], dict):
            raise ValueError(f'既存の設定の構造が異なります: {path}')
        node = node[part]
    if isinstance(value, dict) and isinstance(node.get(parts[-1]), dict):
        merge_dict(node[parts[-1]], value)
    else:
        node[parts[-1]] = copy.deepcopy(value)


def reject_symlink(path):
    """想定外の保存先に書き込まないよう、親ディレクトリを含むリンクを拒否する。"""
    if any(p.is_symlink() for p in [path, *path.parents]):
        raise ValueError(f'シンボリックリンクの保存先には書き込みません: {path}')


def build_plans(snapshot, base):
    """全プロファイルを検証し、ディスクに書き込まずに復元内容を組み立てる。"""
    profiles = snapshot.get('profiles')
    if not isinstance(profiles, dict) or not profiles:
        raise ValueError('profilesが空、または形式が不正です。')
    plans = []
    for name, settings in profiles.items():
        if not re.fullmatch(r'Default|Profile [0-9]+', name):
            raise ValueError(f'不正なChromeプロファイル名: {name}')
        preferences = settings.get('preferences')
        if not isinstance(preferences, dict):
            raise ValueError(f'{name}: preferencesは辞書で指定してください。')
        path = base / name / 'Preferences'
        reject_symlink(path)
        original = path.read_bytes() if path.exists() else None
        data = json.loads(original) if original is not None else {}
        if not isinstance(data, dict):
            raise ValueError(f'{name}: 既存のPreferencesが辞書ではありません。')
        updated = copy.deepcopy(data)
        skipped = []
        for key, value in preferences.items():
            if key in PROTECTED_EXACT or key.startswith(PROTECTED):
                skipped.append(key)
                continue
            set_preference(updated, key, value)
        content = (json.dumps(updated, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode()
        plans.append({'name': name, 'path': path, 'original': original,
                      'content': content, 'changed': updated != data,
                      'skipped': skipped, 'count': len(preferences) - len(skipped)})
    return plans


def restore(snapshot, base, dry_run=False):
    require_closed()
    # 後続プロファイルの検証に失敗しても、先行プロファイルを変更せずに終了する。
    plans = build_plans(snapshot, base)
    for plan in plans:
        name, path = plan['name'], plan['path']
        for key in plan['skipped']:
            print(f'{name}: 保護対象のため自動適用しません: {key}')
        if not plan['changed']:
            print(f'{name}: 設定済み（{plan["count"]}項目）。変更なし。')
            continue
        if dry_run:
            print(f'{name}: {plan["count"]}項目を復元予定（書き込みなし）。')
            continue
        require_closed()
        reject_symlink(path)
        # 読み取り後に別の処理が変更していた場合は、その変更を上書きしない。
        current = path.read_bytes() if path.exists() else None
        if current != plan['original']:
            raise RuntimeError(f'{name}: 読み取り後にPreferencesが変更されました。再実行してください。')
        path.parent.mkdir(parents=True, exist_ok=True)
        # 元データをそのまま保存する。バックアップは所有ユーザーだけが読み書きできる。
        if current is not None:
            stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
            backup = path.with_name('Preferences.before-nix-' + stamp)
            fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, 'wb') as stream:
                stream.write(current)
            print(f'{name}: バックアップ: {backup}')
        # 同じディレクトリに一時ファイルを作り、書き込み完了後に原子的に置き換える。
        # 途中で失敗しても、既存のPreferencesを不完全なJSONにしない。
        fd, temporary = tempfile.mkstemp(prefix='.Preferences.nix-', dir=path.parent)
        try:
            with os.fdopen(fd, 'wb') as stream:
                stream.write(plan['content'])
                stream.flush()
                os.fsync(stream.fileno())
            # 復元中にChromeが起動していないか、置き換え直前にも確認する。
            require_closed()
            if (path.read_bytes() if path.exists() else None) != current:
                raise RuntimeError(f'{name}: 書き込み直前にPreferencesが変更されました。')
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
        print(f'{name}: {plan["count"]}項目を復元しました。Chromeを起動して確認してください。')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', type=Path, required=True)
    parser.add_argument('--user-data-dir', type=Path)
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--check-closed', action='store_true')
    args = parser.parse_args(argv)
    try:
        # root所有の設定を作らないよう、Nix側から対象ユーザーに切り替えて実行する。
        if os.geteuid() == 0:
            raise RuntimeError('対象ユーザーとして実行してください（sudoで直接実行しないでください）。')
        require_closed()
        # Nixの事前チェックでは、Chromeの終了確認だけを行って戻る。
        if args.check_closed:
            return 0
        base = args.user_data_dir or Path(pwd.getpwuid(os.getuid()).pw_dir) / 'Library/Application Support/Google/Chrome'
        snapshot = json.loads(args.snapshot.read_text())
        restore(snapshot, base, args.dry_run)
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f'Chrome設定の復元に失敗しました: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
