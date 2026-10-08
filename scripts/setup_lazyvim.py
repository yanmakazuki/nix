"""Nix管理のLazyVim設定を配置する。既存設定は変更前にバックアップする。"""
import argparse
from datetime import datetime, timezone
from pathlib import Path
import shutil


def install(source, target):
    """管理対象ファイルだけを更新し、それ以外のユーザー設定は残す。"""
    files = [p for p in source.rglob('*') if p.is_file()]
    # 内容が同じなら何もしない。Nixの再適用でバックアップを増やさない。
    changed = any(not (target / p.relative_to(source)).is_file()
                  or (target / p.relative_to(source)).read_bytes() != p.read_bytes()
                  for p in files)
    if not changed:
        return
    if target.is_symlink():
        raise RuntimeError(f'Refusing to replace symlink: {target}')
    # 書き込み先の途中にリンクがある場合も、外部のファイルを変更しないよう拒否する。
    # 全ファイルを先に確認し、検証に失敗した状態では配置を開始しない。
    for p in files:
        dest = target / p.relative_to(source)
        current = dest
        while current != target.parent:
            if current.is_symlink():
                raise RuntimeError(f'Refusing to write through symlink: {dest}')
            current = current.parent
    # 管理対象外のファイルも含めて保存し、変更前の構成を復元できるようにする。
    if target.exists():
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
        backup = target.with_name(target.name + '.before-nix-' + stamp)
        shutil.copytree(target, backup, symlinks=True)
        print(f'Neovim backup: {backup}')
    for p in files:
        dest = target / p.relative_to(source)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(p, dest)
    print(f'LazyVim configuration: {target}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    args = parser.parse_args()
    import os
    # 標準の配置先は ~/.config/nvim。実行ユーザーのXDG設定があれば優先する。
    install(args.source, Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'nvim')
