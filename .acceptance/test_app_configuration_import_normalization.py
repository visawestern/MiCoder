#!/usr/bin/env python3
import unittest
from pathlib import Path


class AppConfigurationImportNormalizationTests(unittest.TestCase):
    def test_import_canonicalizes_registry_before_save(self):
        source = (Path(__file__).resolve().parents[1] / "MiCoder" / "Sources" / "Services" / "AppConfigurationBackupStore.swift").read_text(encoding="utf-8")
        self.assertIn("let normalizedRegistry = ProjectRegistryLogic.deduplicated(registry)", source)
        self.assertIn("ProjectRegistryLogic.save(normalizedRegistry", source)


if __name__ == "__main__":
    unittest.main()
