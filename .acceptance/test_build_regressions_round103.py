#!/usr/bin/env python3
"""Round 103 red/source regressions for the second macOS build log."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
chat = (ROOT / "MiCoder/Sources/Views/ChatPanelView.swift").read_text()
inputs = (ROOT / "MiCoder/Sources/Views/Components/InputViews.swift").read_text()
model = (ROOT / "MiCoder/Sources/Views/Settings/ModelSettingsView.swift").read_text()
db = (ROOT / "MiCoder/Sources/Services/ProjectDatabaseManager.swift").read_text()
watcher = (ROOT / "MiCoder/Sources/Services/ProjectFileIndexWatcher.swift").read_text()
app = (ROOT / "MiCoder/Sources/App/MiCoderApp.swift").read_text()

# SendReadinessReason has effectiveModelID last; both InputViews calls must preserve that ABI.
assert inputs.count("webConnected:") >= 2
assert inputs.count("webConnected: WebProviderConnectivity.configID") >= 2
# The final call must place effectiveModelID after the webConnected argument.
assert inputs.count("effectiveModelID: appState.effectiveSelectedModel(),\n            serverConnected:") == 0
assert inputs.count("effectiveModelID: appState.effectiveSelectedModel(),\n            serverConnected:") < 2

# SQLite left operand must be the column expression, not the shadowing parameter.
assert "self.sessionGoal <- sessionGoalValue" in db

# CoreServices exposes these flags as UInt32 constants, not Swift OptionSet literals.
assert "kFSEventStreamCreateFlagFileEvents" in watcher
assert "kFSEventStreamCreateFlagNoDefer" in watcher
assert "FSEventStreamCreateFlags([.fileEvents, .noDefer])" not in watcher

# Force a Color result context before calling opacity; Double alone was insufficient.
assert "let metadataBackground: Color = Color.mimo.backgroundAlt.opacity(0.45)" in model
assert ".background(metadataBackground)" in model

# Keep public synchronous selection callers intact; hop only the MainActor journal.
assert "@MainActor\n    func selectWebEffort" not in app
assert "@MainActor\n    func selectModel" not in app
assert app.count("Task { @MainActor in") >= 2
assert app.count('self.recordWebBrowserAction(action: "effort_selected"') == 1
assert app.count('self.recordWebBrowserAction(action: "model_selected"') == 1

print("Round 103 build-regression source acceptance: PASS")
