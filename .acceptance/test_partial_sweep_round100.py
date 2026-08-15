#!/usr/bin/env python3
"""Round 100 source regressions for WEB-26/MODEL-19 and DNG future policy."""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
chat = (ROOT / "MiCoder/Sources/Views/ChatPanelView.swift").read_text()
auto_free = (ROOT / "MiCoder/Sources/Services/MiCoderAutoFreeProvider.swift").read_text()
status_logic = (ROOT / "MiCoder/Sources/Services/MiCoderAutoFreeCatalogStatusLogic.swift").read_text()

assert "WebRetryContextLogic.isFirstMessageForRetry(originalIsFirst: isFirst)" in chat, "retry must preserve original first-turn context"
assert "MiCoderAutoFreeCatalogStatusLogic.statusAfterRefresh" in auto_free, "refresh must use status-preservation policy"
assert "previousStatus" in status_logic and "previousSelectedModel" in status_logic, "status policy must compare pre/post catalog state"

with (ROOT / "docs/FEATURE_SPREADSHEET.csv").open(newline="") as f:
    rows = {row["id"]: row for row in csv.DictReader(f)}
assert rows["DNG-01"]["status"] == "FUTURE", "DNG-01 must remain explicit FUTURE by product policy"
assert rows["DNG-01"]["expected_behavior"] == "NOT IMPLEMENTED - future"
print("Round 100 partial sweep source acceptance: PASS")
