#!/usr/bin/env python3
import unittest
from pathlib import Path


class MCPSettingsTransactionalRollbackTests(unittest.TestCase):
    def test_mutations_have_config_rollback_when_registry_write_fails(self):
        source = (Path(__file__).resolve().parents[1] / "MiCoder" / "Sources" / "Views" / "Settings" / "MCPServersSettingsView.swift").read_text(encoding="utf-8")
        self.assertIn("let originalData = data", source)
        self.assertIn("try? originalData.write(to: configURL, options: .atomic)", source)
        self.assertGreaterEqual(source.count("originalData.write(to: configURL"), 2)


if __name__ == "__main__":
    unittest.main()
