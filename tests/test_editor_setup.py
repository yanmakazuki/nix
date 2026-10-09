"""Terminalのフォント設定で既存プロファイルを保持できるか検証する。"""
import importlib.util
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch

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


class TerminalIOTests(unittest.TestCase):
    def test_read_existing_preferences(self):
        original = {'SecureKeyboardEntry': True}
        result = subprocess.CompletedProcess([], 0, plistlib.dumps(original), b'')
        with patch.object(terminal.subprocess, 'run', return_value=result):
            self.assertEqual(terminal.read_preferences(), original)

    def test_missing_domain_and_read_errors(self):
        for message in (b'domain does not exist', b'domain not found'):
            with self.subTest(message=message):
                result = subprocess.CompletedProcess([], 1, b'', message)
                with patch.object(terminal.subprocess, 'run', return_value=result):
                    self.assertEqual(terminal.read_preferences(), {})
        result = subprocess.CompletedProcess([], 1, b'', b'permission denied')
        with patch.object(terminal.subprocess, 'run', return_value=result):
            with self.assertRaises(RuntimeError):
                terminal.read_preferences()

    def test_backup_preserves_original_and_permissions(self):
        original = {'Window Settings': {'Custom': {'Font': b'old'}}}
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            with patch.object(terminal.Path, 'home', return_value=Path(directory)):
                backup = terminal.backup_preferences(original)
            self.assertEqual(plistlib.loads(backup.read_bytes()), original)
            self.assertEqual(backup.stat().st_mode & 0o777, 0o600)

    def test_setup_already_configured_skips_writes(self):
        original = terminal.update_preferences({}, b'font')
        with patch.object(terminal, 'font_archive', return_value=b'font'), \
             patch.object(terminal, 'read_preferences', return_value=original), \
             patch.object(terminal, 'backup_preferences') as backup, \
             patch.object(terminal.subprocess, 'run') as run:
            terminal.setup(Path('unused'))
        backup.assert_not_called()
        run.assert_not_called()
