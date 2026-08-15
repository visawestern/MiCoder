#!/usr/bin/env python3
"""Round 105 red/source regression for the native FSEvents callback binding."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "MiCoder/Sources/Services/ProjectFileIndexWatcher.swift").read_text()

# The macOS CoreServices import exposes client info as optional but the event
# path buffer as a non-optional UnsafeMutableRawPointer. Binding both with
# `guard let` fails exactly as reported by the user's native compiler.
assert "guard let info else { return }" in source
assert "guard let info, let pathPointers else" not in source
assert "let typedPaths = pathPointers.assumingMemoryBound" in source
assert "Unmanaged<ProjectFileIndexWatcher>" in source
assert "FSEventStreamContext(" in source

print("Round 105 FSEvents callback source acceptance: PASS")
