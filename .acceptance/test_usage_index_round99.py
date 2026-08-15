#!/usr/bin/env python3
"""Round 99 source regressions for usage token safety and file search."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
usage_capture = (ROOT / "MiCoder/Sources/Services/UsageStatisticsAggregator.swift").read_text()
usage_point = (ROOT / "MiCoder/Sources/Services/UsageDataPoint.swift").read_text()
record = (ROOT / "MiCoder/Sources/Services/FileIndexRecord.swift").read_text()
logic = (ROOT / "MiCoder/Sources/Services/ProjectFileSearchLogic.swift").read_text()
scanner = (ROOT / "MiCoder/Sources/Services/ProjectFileScanner.swift").read_text()

assert "max(0, promptTokens)" in usage_capture and "max(0, completionTokens)" in usage_capture, "provider usage tokens must clamp at zero"
assert "max(0, promptTokens)" in usage_point and "max(0, completionTokens)" in usage_point, "persisted usage tokens must clamp at zero"
assert "var searchableText: String?" in record, "file index must persist optional searchable text"
assert "ProjectFileIndexLogic.defaultSearchableTextMaxBytes" in scanner, "file text indexing must be bounded"
assert "record.language.caseInsensitiveCompare(\"binary\")" in logic, "binary records must be excluded from search"
assert "allSatisfy" in logic, "file search must require all query terms"
print("Round 99 usage/index source acceptance: PASS")
