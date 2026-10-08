"""エディタ設定のバックアップ・再適用・既存設定の保持を検証する。"""
import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


lazyvim = load('setup_lazyvim')
terminal = load('setup_terminal_font')


# 実際のホームディレクトリやTerminal設定には書き込まず、一時領域と辞書で検証する。
class EditorSetupTests(unittest.TestCase):
    def test_lazyvim_backup_preservation_and_idempotence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / 'source'
            target = root / 'nvim'
            source.mkdir()
            target.mkdir()
            (source / 'init.lua').write_text('new')
            (target / 'init.lua').write_text('old')
            (target / 'custom.lua').write_text('keep')
            lazyvim.install(source, target)
            backups = list(root.glob('nvim.before-nix-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / 'init.lua').read_text(), 'old')
            self.assertEqual((target / 'init.lua').read_text(), 'new')
            self.assertEqual((target / 'custom.lua').read_text(), 'keep')
            lazyvim.install(source, target)
            self.assertEqual(list(root.glob('nvim.before-nix-*')), backups)

    def test_lazyvim_symlink_is_not_written(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / 'source'
            target = root / 'nvim'
            source.mkdir()
            target.mkdir()
            (source / 'init.lua').write_text('new')
            outside = root / 'outside'
            outside.write_text('old')
            (target / 'init.lua').symlink_to(outside)
            with self.assertRaises(RuntimeError):
                lazyvim.install(source, target)
            self.assertEqual(outside.read_text(), 'old')

    def test_terminal_preserves_colors_and_profile_selection(self):
        original = {'Window Settings': {'Custom': {'Font': b'old', 'Color': b'color'}},
                    'Default Window Settings': 'Custom', 'Startup Window Settings': 'Custom',
                    'SecureKeyboardEntry': True}
        prefs = terminal.update_preferences(original, b'font')
        self.assertEqual(prefs['Window Settings']['Custom'], {'Font': b'font', 'Color': b'color'})
        self.assertEqual(prefs['Default Window Settings'], 'Custom')
        self.assertTrue(prefs['SecureKeyboardEntry'])
        self.assertEqual(original['Window Settings']['Custom']['Font'], b'old')
        self.assertEqual(terminal.update_preferences(prefs, b'font'), prefs)
        self.assertEqual(plistlib.loads(plistlib.dumps(prefs)), prefs)

    def test_terminal_fresh_preferences(self):
        prefs = terminal.update_preferences({}, b'font')
        self.assertEqual(prefs['Window Settings']['Basic']['Font'], b'font')
        self.assertEqual(prefs['Default Window Settings'], 'Basic')
        self.assertEqual(prefs['Startup Window Settings'], 'Basic')

    def test_terminal_invalid_profiles_fail(self):
        with self.assertRaises(ValueError):
            terminal.update_preferences({'Window Settings': {'Basic': 'invalid'}}, b'font')
