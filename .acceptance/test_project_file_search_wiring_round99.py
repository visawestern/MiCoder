#!/usr/bin/env python3
"""Round 99 source regression for user-visible project-file search."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
app = (ROOT / "MiCoder/Sources/App/MiCoderApp.swift").read_text()
sidebar = (ROOT / "MiCoder/Sources/Views/SidebarView.swift").read_text()

assert "func searchProjectFiles(query: String)" in app, "AppState must expose indexed project-file search"
assert "ProjectFileSearchLogic.search(" in app and "query: query" in app, "AppState must search persisted project records"
assert "matchingFiles" in sidebar, "Search palette must render project-file matches"
assert "activateFileViewerSelecting" in sidebar, "File result action must reveal the selected project file"
print("Round 99 project-file search wiring acceptance: PASS")
