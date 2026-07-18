import importlib.util
from pathlib import Path
import unittest

MODULE_PATH = Path(__file__).resolve().parents[1] / "petlovers" / "security.py"
SPEC = importlib.util.spec_from_file_location("petlovers_security", MODULE_PATH)
SECURITY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SECURITY)


class PasswordTests(unittest.TestCase):
    def test_hash_and_verify(self):
        encoded = SECURITY.hash_password("Prueba#2026!")
        self.assertTrue(SECURITY.verify_password("Prueba#2026!", encoded))
        self.assertFalse(SECURITY.verify_password("incorrecta", encoded))


if __name__ == "__main__":
    unittest.main()
