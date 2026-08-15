#!/usr/bin/env python3
"""Round 98 source regression for web Stop/cancellation post-driver flow."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
driver = (ROOT / "MiCoder/Sources/Services/WebChatDriver.swift").read_text()
chat = (ROOT / "MiCoder/Sources/Views/ChatPanelView.swift").read_text()

assert "try Task.checkCancellation()" in driver, "web driver must observe Task cancellation"
assert "catch is CancellationError" in driver, "web cancellation must terminate silently"
assert "WebChatCancellationLogic.shouldStopAfterDriver(isCancelled: Task.isCancelled)" in chat, "ChatPanel must stop post-driver flow"
assert chat.count("WebChatCancellationLogic.shouldStopAfterDriver(isCancelled: Task.isCancelled)") >= 2, "cancelled original/retry turns must stop post-driver continuation"
print("Round 98 web cancellation source acceptance: PASS")
