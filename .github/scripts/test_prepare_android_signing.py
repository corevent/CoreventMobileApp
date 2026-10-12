import base64
import os
from pathlib import Path
import stat
import tempfile
import unittest

from prepare_android_signing import SECRET_NAMES, escape_property, prepare_signing


class AndroidSigningTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.workspace = self.root / "workspace"
        (self.workspace / "android").mkdir(parents=True)
        self.temporary = self.root / "temporary"
        self.temporary.mkdir()
        self.secrets = {
            "ANDROID_KEYSTORE_BASE64": base64.b64encode(b"test-keystore").decode(),
            "ANDROID_STORE_PASSWORD": "store-password",
            "ANDROID_KEY_ALIAS": "upload",
            "ANDROID_KEY_PASSWORD": "key-password",
        }

    def prepare(self):
        return prepare_signing(self.workspace, self.temporary, self.secrets)

    def test_decodes_keystore_and_uses_temporary_absolute_path(self):
        self.secrets["ANDROID_KEYSTORE_BASE64"] += "\n"
        keystore, properties = self.prepare()
        self.assertEqual(keystore.read_bytes(), b"test-keystore")
        content = properties.read_text(encoding="utf-8")
        self.assertIn("storeFile=" + escape_property(str(keystore.resolve())), content)
        self.assertIn("keyAlias=upload\n", content)
        if os.name != "nt":
            self.assertEqual(stat.S_IMODE(keystore.stat().st_mode), 0o600)
            self.assertEqual(stat.S_IMODE(properties.stat().st_mode), 0o600)

    def test_preserves_special_characters_without_properties_injection(self):
        self.secrets["ANDROID_STORE_PASSWORD"] = " café\\secret:=#! \nstoreFile=other\r\t"
        _, properties = self.prepare()
        content = properties.read_text(encoding="utf-8")
        self.assertEqual(len(content.splitlines()), 4)
        self.assertIn(
            r"storePassword=\ café\\secret\:\=\#\!\ \nstoreFile\=other\r\t",
            content,
        )

    def test_missing_or_blank_secret_creates_no_files_and_reports_only_name(self):
        for name in SECRET_NAMES:
            with self.subTest(name=name):
                original = self.secrets[name]
                self.secrets[name] = "  "
                with self.assertRaisesRegex(ValueError, name) as failure:
                    self.prepare()
                self.assertNotIn("store-password", str(failure.exception))
                self.assertNotIn("key-password", str(failure.exception))
                self.assertFalse((self.workspace / "android" / "key.properties").exists())
                self.assertEqual(list(self.temporary.iterdir()), [])
                self.secrets[name] = original

    def test_invalid_base64_is_rejected_without_leaking_input(self):
        self.secrets["ANDROID_KEYSTORE_BASE64"] = "invalid-private-value!"
        with self.assertRaises(ValueError) as failure:
            self.prepare()
        self.assertNotIn("invalid-private-value", str(failure.exception))
        self.assertEqual(list(self.temporary.iterdir()), [])

    def test_empty_decoded_keystore_is_rejected(self):
        self.secrets["ANDROID_KEYSTORE_BASE64"] = "===="
        with self.assertRaises(ValueError):
            self.prepare()
        self.assertEqual(list(self.temporary.iterdir()), [])


if __name__ == "__main__":
    unittest.main()

