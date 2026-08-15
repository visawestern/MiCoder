#!/usr/bin/env python3
"""Round 104 red/source regressions for the third macOS build log."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
watcher = (ROOT / "MiCoder/Sources/Services/ProjectFileIndexWatcher.swift").read_text()
model = (ROOT / "MiCoder/Sources/Views/Settings/ModelSettingsView.swift").read_text()
inputs = (ROOT / "MiCoder/Sources/Views/Components/InputViews.swift").read_text()

# CoreServices constants bridge as Int on the user's SDK and must be explicitly
# converted to the UInt32/FSEventStreamCreateFlags expected by the API.
assert re.search(r"UInt32\(\s*truncatingIfNeeded:", watcher)
assert "FSEventStreamCreateFlags" in watcher
assert "kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer" in watcher
assert "eventFlags\n        )" in watcher

# Numeric optional parameter values need an explicit description closure in Text.
assert "map { String(describing: $0) }" in model
assert "map(String.init)" not in model

# `canSendMessage` has no effectiveModelID parameter; the human-readable
# `SendReadinessReason.reason` API does. Inspect each call boundary separately.
can_send_calls = re.findall(r"SendReadinessLogic\.canSendMessage\((.*?)\n\s*\)", inputs, re.S)
assert len(can_send_calls) == 2
assert all("effectiveModelID" not in call for call in can_send_calls)
reason_calls = re.findall(r"SendReadinessReason\.reason\((.*?)\n\s*\)", inputs, re.S)
assert len(reason_calls) == 2
assert all(call.rstrip().endswith("effectiveModelID: appState.effectiveSelectedModel()") for call in reason_calls)

print("Round 104 build-regression source acceptance: PASS")
