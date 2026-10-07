import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/restore_chrome_settings.py'
spec = importlib.util.spec_from_file_location('restore', SCRIPT)
restore = importlib.util.module_from_spec(spec)
spec.loader.exec_module(restore)


class RestoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parents[1])
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name) / 'Chrome'
        self.path = self.base / 'Default' / 'Preferences'
        self.snapshot = {'profiles': {'Default': {'preferences': {
            'bookmark_bar.show_on_all_tabs': False,
            'profile.default_content_setting_values.notifications': 2,
            'accessibility.captions': {'headless_caption_enabled': False},
            'intl.selected_languages': 'en-US,en',
            'extensions.theme.id': 'do-not-write',
        }, 'policyCandidates': {'DefaultNotificationsSetting': 1}}}}
        self.closed = patch.object(restore, 'chrome_is_running', return_value=False)
        self.closed.start()
        self.addCleanup(self.closed.stop)

    def write_existing(self, data):
        self.path.parent.mkdir(parents=True)
        content = json.dumps(data, ensure_ascii=False).encode()
        self.path.write_bytes(content)
        return content

    def test_merge_backup_and_idempotence(self):
        original = self.write_existing({
            'bookmark_bar': {'show_on_all_tabs': True, 'other_setting': 7},
            'profile': {'default_content_setting_values': {'geolocation': 3}},
            'accessibility': {'captions': {'unrelated_caption_setting': '保持'}},
            'extensions': {'theme': {'id': 'existing-theme'}},
            'unrelated': {'value': '日本語'},
        })
        restore.restore(self.snapshot, self.base)
        data = json.loads(self.path.read_text())
        self.assertFalse(data['bookmark_bar']['show_on_all_tabs'])
        self.assertEqual(data['bookmark_bar']['other_setting'], 7)
        self.assertEqual(data['profile']['default_content_setting_values'], {'geolocation': 3, 'notifications': 2})
        self.assertEqual(data['extensions']['theme']['id'], 'existing-theme')
        self.assertEqual(data['accessibility']['captions']['unrelated_caption_setting'], '保持')
        self.assertEqual(data['unrelated']['value'], '日本語')
        backups = list(self.path.parent.glob('Preferences.before-nix-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), original)
        after = self.path.read_bytes()
        restore.restore(self.snapshot, self.base)
        self.assertEqual(self.path.read_bytes(), after)
        self.assertEqual(len(list(self.path.parent.glob('Preferences.before-nix-*'))), 1)

    def test_fresh_profile(self):
        restore.restore(self.snapshot, self.base)
        data = json.loads(self.path.read_text())
        self.assertEqual(data['profile']['default_content_setting_values']['notifications'], 2)
        self.assertNotIn('extensions', data)
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o600)

    def test_dry_run_creates_nothing(self):
        restore.restore(self.snapshot, self.base, dry_run=True)
        self.assertFalse(self.base.exists())

    def test_running_browser_writes_nothing(self):
        original = self.write_existing({'untouched': True})
        with patch.object(restore, 'chrome_is_running', return_value=True):
            with self.assertRaises(RuntimeError):
                restore.restore(self.snapshot, self.base)
        self.assertEqual(self.path.read_bytes(), original)
        self.assertEqual(list(self.path.parent.glob('Preferences.before-nix-*')), [])

    def test_browser_starting_mid_restore_does_not_replace(self):
        original = self.write_existing({'untouched': True})
        with patch.object(restore, 'chrome_is_running', side_effect=[False, False, True]):
            with self.assertRaises(RuntimeError):
                restore.restore(self.snapshot, self.base)
        self.assertEqual(self.path.read_bytes(), original)
        self.assertEqual(list(self.path.parent.glob('.Preferences.nix-*')), [])

    def test_malformed_existing_file_is_preserved(self):
        self.path.parent.mkdir(parents=True)
        self.path.write_bytes(b'not json')
        with self.assertRaises(ValueError):
            restore.restore(self.snapshot, self.base)
        self.assertEqual(self.path.read_bytes(), b'not json')

    def test_invalid_second_profile_prevents_all_writes(self):
        self.snapshot['profiles']['../escape'] = {'preferences': {'anything': 1}}
        with self.assertRaises(ValueError):
            restore.restore(self.snapshot, self.base)
        self.assertFalse(self.base.exists())

    def test_symlink_is_not_followed(self):
        outside = Path(self.tmp.name) / 'outside'
        outside.mkdir()
        self.base.mkdir()
        (self.base / 'Default').symlink_to(outside, target_is_directory=True)
        with self.assertRaises(ValueError):
            restore.restore(self.snapshot, self.base)
        self.assertEqual(list(outside.iterdir()), [])

    def test_structure_conflict_is_not_overwritten(self):
        original = self.write_existing({'profile': 'unexpected scalar'})
        with self.assertRaises(ValueError):
            restore.restore(self.snapshot, self.base)
        self.assertEqual(self.path.read_bytes(), original)


if __name__ == '__main__':
    unittest.main()
