#!/usr/bin/env python3
import csv
import unittest
from pathlib import Path


class FeatureRegistryIntegrityTests(unittest.TestCase):
    def test_story_ids_are_nonempty_and_unique(self):
        registry = Path(__file__).resolve().parents[1] / "docs" / "FEATURE_SPREADSHEET.csv"
        with registry.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle))
        ids = [row["id"].strip() for row in rows]
        self.assertEqual(len(rows), 274)
        self.assertTrue(all(ids))
        self.assertEqual(len(ids), len(set(ids)), "canonical story IDs must be unique")


if __name__ == "__main__":
    unittest.main()
