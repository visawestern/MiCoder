#!/usr/bin/env python3
import re
import unittest
from pathlib import Path


class StorageDeletionWiringTests(unittest.TestCase):
    def test_settings_delete_wires_progress_and_cancellation(self):
        source = (Path(__file__).resolve().parents[1] / "MiCoder" / "Sources" / "Views" / "Settings" / "StorageSettingsView.swift").read_text(encoding="utf-8")
        self.assertRegex(source, r"@State\s+private var deletionProgress")
        self.assertRegex(source, r"@State\s+private var deletionCancelRequested")
        self.assertIn("ProgressView(value: deletionProgress)", source)
        self.assertIn("Cancel deletion", source)
        execute = re.search(
            r"ProjectDeletionExecutor\.execute\(.*?\n\s*\)",
            source,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(execute)
        call = execute.group(0)
        self.assertIn("shouldCancel:", call)
        self.assertIn("onProgress:", call)


if __name__ == "__main__":
    unittest.main()
