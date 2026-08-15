#!/usr/bin/env python3
"""Round 98 source regression for active WebKit stop routing."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
app = (ROOT / "MiCoder/Sources/App/MiCoderApp.swift").read_text()
chat = (ROOT / "MiCoder/Sources/Views/ChatPanelView.swift").read_text()

assert "func stopWebGeneration(providerID: String," in app and "projectID: String," in app and "chatID: String) async" in app, "stop API must identify the active browser instance"
assert "webView(for: config, projectID: projectID, chatID: chatID)" in app, "stop must address the active project/chat WebView"
assert "await appState.stopWebGeneration(" in chat and "providerID: providerID" in chat and "projectID: projectID" in chat and "chatID: chatID" in chat, "ChatPanel must pass the active project/chat to stop"
assert "activeWebChatID" in chat, "ChatPanel must retain the active web chat identity"
print("Round 98 web stop-routing source acceptance: PASS")
