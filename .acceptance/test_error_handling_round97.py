#!/usr/bin/env python3
"""Persistent source acceptance regressions for Round 97 ERR-01/02/03."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
chat = (ROOT / "MiCoder/Sources/Views/ChatPanelView.swift").read_text()
client = (ROOT / "MiCoder/Sources/Services/MimoServeClient.swift").read_text()
feedback = (ROOT / "MiCoder/Sources/Services/ServeResponseFeedbackLogic.swift").read_text()
transport = (ROOT / "MiCoder/Sources/Services/ServeTransportFailureLogic.swift").read_text()
retry = (ROOT / "MiCoder/Sources/Services/SessionBusyRetryLogic.swift").read_text()

assert "responseCount: responseMessages.count" in chat, "Serve finalization must validate empty response arrays"
assert "ServeTransportFailureLogic.shouldMarkServerDisconnected" in chat, "Serve disconnect classification must be wired"
assert "self.appState.serverConnected = false" in chat, "Serve transport loss must clear stale connectivity"
assert "self.appState.notificationService.serverDisconnected()" in chat, "Serve transport loss must notify the user"
assert "ServeTransportFailureLogic.isConnectionFailure(error)" in client, "sendMessage must map raw transport failures"
assert "throw MimoServeError.connectionFailed" in client, "mapped transport failure must use the typed Serve error"
assert "responseCount: Int" in feedback, "feedback helper must accept response cardinality"
assert "error is URLError" in transport, "URLSession transport errors must fail closed"
assert "isCancelled: Bool = false" in retry, "retry planning must accept cancellation state"
assert "isCancelled: Task.isCancelled" in chat, "ChatPanel must pass cancellation into retry planner"
assert chat.count("guard !Task.isCancelled") >= 3, "busy recovery must guard before/after abort and sleep"
print("Round 97 error-handling source acceptance: PASS")
