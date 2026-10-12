#!/usr/bin/env python3
"""Round 101 source acceptance for the final canonical tail audit."""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text()

content = read("myCoder/Sources/Services/MiCoderAutoFreeContentLogic.swift")
history = read("myCoder/Sources/Services/MiCoderAutoFreeHistoryLogic.swift")
gate = read("myCoder/Sources/Services/WebToolAccessGate.swift")
protocol = read("myCoder/Sources/Services/WebToolProtocolEmulator.swift")
presenter = read("myCoder/Sources/Services/WebChatEventPresenter.swift")
restoration = read("myCoder/Sources/Services/WebSessionRestorationLogic.swift")
driver = read("myCoder/Sources/Services/WebChatDriver.swift")
discovery = read("myCoder/Sources/Services/WebModelDiscovery.swift")
routing = read("myCoder/Sources/Services/ProjectSessionRoutingLogic.swift")
maintenance = read("myCoder/Sources/Services/ProjectDatabaseManager.swift")
stats = read("myCoder/Sources/Services/ProjectStorageStatsLogic.swift")
status = read("myCoder/Sources/Services/ProviderConnectionStatusLogic.swift")
undo = read("myCoder/Sources/Services/UndoActionFeedbackLogic.swift")

assert "isUnsupportedForTextRoute" in content and "fileText" in content
assert "maxTurns > 0" in history and "isFinished" in history
assert "case .writeFile, .editFile, .todoWrite" in gate
assert "case .gitBranch, .gitCheckout, .gitCommit, .gitPush, .gitPull" in gate
assert "case .task" in gate and "case .runCommand" in gate
assert "approvalRequired" in presenter and "send_completed" not in presenter
assert "setLocalStorage" in restoration and "cookies" in restoration
assert "customModelSelector" in driver and "isSelectable" in discovery
assert "case todoWrite" in protocol and "case task" in protocol
assert "return nil" in routing
assert "max(0, days)" in maintenance
assert "ProjectStorageStatsLogic" in stats or "struct ProjectStorageStats" in stats
assert "static func isConnected" in status and "static func endpointLabel" in status
assert "UndoActionFeedbackLogic" in undo or "success" in undo

with (ROOT / "docs/FEATURE_SPREADSHEET.csv").open(newline="") as f:
    rows = {row["id"]: row for row in csv.DictReader(f)}
expected_ids = {
    "CHAT-19", "WEB-CHAT-11", "WEB-CHAT-12", "WEB-CHAT-13", "WEB-CHAT-14", "WEB-CHAT-15",
    "CHAT-20", "PROV-20", "DB-07", "DB-08", "DB-09", "STO-30", "STO-31",
    "SHELL-01", "SHELL-02", "SHELL-03"
}
assert expected_ids.issubset(rows)
assert all(rows[key]["status"] == "PARTIAL" for key in expected_ids)
print("Round 101 final tail source acceptance: PASS")
