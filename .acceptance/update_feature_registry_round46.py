import csv
from pathlib import Path

path = Path('/home/ubuntu/MiCoder/docs/FEATURE_SPREADSHEET.csv')
with path.open(newline='') as f:
    rows = list(csv.DictReader(f))
    fields = list(rows[0].keys())

for row in rows:
    if row['id'] == 'WEB-19':
        row['status'] = 'PARTIAL'
        row['notes'] = 'Round 46: structured live profile is persisted and shown in settings; live Kimi/Qwen WebKit verification remains pending.'
    elif row['id'] == 'WEB-20':
        row['status'] = 'PARTIAL'
        row['notes'] = 'Round 46: pre-send injection failure blocks duplicate typing, refreshes the same project/chat page once, then retries; macOS failure trigger remains pending.'
    elif row['id'] == 'WEB-21':
        row['status'] = 'PARTIAL'
        row['notes'] = 'Round 46: sessionID now keys both cookies and hidden WKWebView instances; live two-account WebKit switching remains pending.'

new_rows = [
    ['Web', 'WEB-22', 'Strict Web Model Candidate Validation', 'As a user, I want headings, actions, effort labels and container text rejected from the model catalog', 'Only visible selectable leaf model options with vendor-valid IDs enter the live catalog; rejected noise stays out of allModels and is explainable in review evidence', 'WebModelDiscoveryTests; WebModelListParserQwenTests; adversarial source checks', 'PARTIAL', 'Round 46 implemented and Foundation-tested; live vendor DOM verification pending'],
    ['Web', 'WEB-23', 'Recursive Nested Model Expansion', 'As a user, I want every model behind Expand more models, including Qwen Coder branches, discovered', 'Exact expansion controls are traversed with changing DOM fingerprint/count until exhausted; duplicate/noise entries are filtered', 'WebModelDiscoveryTests.discoverAllModelsTraversesTwoExpansionLevelsAndRejectsHeadings', 'PARTIAL', 'Two-level fake regression passes; live Qwen menu verification pending'],
    ['Web', 'WEB-24', 'Per-Model Capability and Selectability Status', 'As a user, I want active, inactive, unsupported and not-detected model states plus per-model effort/profile controls', 'Each model stores status, isSelectable, efforts and parameter profile; unsupported effort is hidden and unselectable candidates cannot be sent', 'WebBrowserRuntimeTests; WebProviderSelectionLogicTests; ModelSettingsView', 'PARTIAL', 'Code and Foundation checks pass; live capability probe pending'],
    ['Web', 'WEB-25', 'Remote Chat UUID Routing', 'As a user, I want each local project/chat/session to map to one verified remote web chat UUID', 'A new local mapping creates an exact New Chat and verifies URL/UUID change; existing mappings navigate by verified URL/UUID and fail closed on mismatch', 'WebRemoteChatStore; WebBrowserRuntimeTests; ChatPanelView', 'PARTIAL', 'Persistence, journal and source-chain checks pass; live provider routing pending'],
    ['Web', 'WEB-26', 'Automatic Safe Catalog Retry', 'As a user, I want model/effort injection failure refreshed and retried without duplicate text or context mixing', 'Injection fails before typing, one same-page catalog refresh occurs, refreshed config retries once in the same remote chat and journal', 'WebProviderSelectionLogicTests; ChatPanelView; adversarial source checks', 'PARTIAL', 'Foundation and source checks pass; live WebKit failure injection pending'],
    ['Web', 'WEB-27', 'AI Detection Isolation', 'As a user, I want AI-assisted detection separate from built-in DOM detection and unable to invent sendable models', 'AI output uses strict vendor validation and is stored as unselectable review candidates; DOM detection remains the only activation path', 'WebProvidersSection.swift; WebModelListParser.swift; adversarial source checks', 'PARTIAL', 'Code path and source checks pass; live AI/browser comparison pending'],
]
existing_ids = {row['id'] for row in rows}
for values in new_rows:
    if values[1] not in existing_ids:
        rows.append(dict(zip(fields, values)))

with path.open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    writer.writerows(rows)
print(f'rows={len(rows)}')
