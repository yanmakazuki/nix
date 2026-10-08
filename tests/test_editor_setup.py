"""Terminalのフォント設定で既存プロファイルを保持できるか検証する。"""
import importlib.util
from pathlib import Path
import plistlib
import unittest

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


terminal = load('setup_terminal_font')


# 実際のホームディレクトリやTerminal設定には書き込まず、一時領域と辞書で検証する。
class EditorSetupTests(unittest.TestCase):
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
