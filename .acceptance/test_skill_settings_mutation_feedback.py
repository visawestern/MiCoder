#!/usr/bin/env python3
import unittest
from pathlib import Path


class SkillSettingsMutationFeedbackTests(unittest.TestCase):
    def test_skill_row_does_not_silently_discard_toggle_failures(self):
        source = (Path(__file__).resolve().parents[1] / "MiCoder" / "Sources" / "Views" / "Settings" / "SkillsSettingsView.swift").read_text(encoding="utf-8")
        self.assertIn("@State private var mutationError: String?", source)
        self.assertIn("if let mutationError", source)
        self.assertNotIn("_ = try? SkillRegistryManager.setEnabled", source)


if __name__ == "__main__":
    unittest.main()
