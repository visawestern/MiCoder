#!/usr/bin/env python3
"""Round 102 red/green source regressions for the reported macOS build log."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
chat = (ROOT / "MiCoder/Sources/Views/ChatPanelView.swift").read_text()
inputs = (ROOT / "MiCoder/Sources/Views/Components/InputViews.swift").read_text()
storage = (ROOT / "MiCoder/Sources/Views/Settings/StorageSettingsView.swift").read_text()
db = (ROOT / "MiCoder/Sources/Services/ProjectDatabaseManager.swift").read_text()
app = (ROOT / "MiCoder/Sources/App/MiCoderApp.swift").read_text()
model_settings = (ROOT / "MiCoder/Sources/Views/Settings/ModelSettingsView.swift").read_text()
watcher = (ROOT / "MiCoder/Sources/Services/ProjectFileIndexWatcher.swift").read_text()

# The generated call sites must match SendReadinessLogic's public label order.
for source, label in ((chat, "ChatPanelView"), (inputs, "InputViews")):
    assert source.count("providerID:") >= 2, f"{label} must pass providerID"
    if "effectiveModelID: appState.effectiveSelectedModel(),\n            providerID:" in source:
        raise AssertionError(f"{label} still passes effectiveModelID before providerID")
    if "effectiveModelID: sendOptions" in source:
        raise AssertionError(f"{label} has stale effectiveModelID label ordering")

# Swift 6 must have an explicit compactMap result type for Auto Free image URLs.
assert "compactMap { (image: ClipboardImage) -> String? in" in chat

# Optional path mapping must map the workspace/path value, not String characters.
assert "selectedWorkspace?.path.map {" not in storage
assert "selectedWorkspace.map { workspace in" in storage
assert "workspace.path" in storage

# SQLite column expression must be disambiguated from the optional parameter.
assert "sessionGoal <- sessionGoalValue" in db

# Synchronous AppState selection methods must be MainActor-isolated before calling the journal.
assert "@MainActor\n    func selectWebEffort" in app
assert "@MainActor\n    func selectModel" in app

# SwiftUI and CoreServices APIs need explicit static types on the macOS toolchain.
assert "backgroundAlt.opacity(Double(0.45))" in model_settings
assert "FSEventStreamCreateFlags([.fileEvents, .noDefer])" in watcher
assert "guard let json = try JSONSerialization.jsonObject" not in app

print("Round 102 build-regression source acceptance: PASS")
