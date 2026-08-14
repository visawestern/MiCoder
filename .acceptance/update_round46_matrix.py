import csv
from pathlib import Path

path = Path('/home/ubuntu/MiCoder/.acceptance/ACCEPTANCE_MATRIX.csv')
score_updates = {
    'AUD-01': ('PARTIAL', 4, 4, 'UNVERIFIED', 'Canonical registry remains present; independent round artifacts now make verification boundaries explicit.'),
    'AUD-02': ('PARTIAL', 3, 3, 'UNVERIFIED', 'Round 46 adds adversarial regression and retest evidence; full macOS cycle remains unavailable in Linux.'),
    'AUD-03': ('PARTIAL', 3, 3, 'UNVERIFIED', 'Auto Free live-catalog guard and failover severity were hardened; anonymous endpoint response remains unverified.'),
    'AUD-04': ('PARTIAL', 4, 4, 'UNVERIFIED', 'MiCoder Auto Free remains the active route; historical compatibility references are not runtime user-facing.'),
    'AUD-05': ('PARTIAL', 3, 3, 'UNVERIFIED', 'Live allow-list guard is enforced before stream send; endpoint/authentication success remains unverified.'),
    'AUD-06': ('PARTIAL', 4, 4, 'UNVERIFIED', 'Rate-limit notifications now use error severity and red banner path; macOS visual proof remains unverified.'),
    'AUD-07': ('PARTIAL', 4, 4, 'UNVERIFIED', 'Catalog/status/profile UI and model lock state are hardened; live catalog completeness remains unverified.'),
    'AUD-08': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Provider-local controls, named session picker, full accordion and remove actions are present; hit-target runtime remains unverified.'),
    'AUD-09': ('PARTIAL', 4, 4, 'UNVERIFIED', 'Existing source implementation remains; no new target interaction evidence.'),
    'AUD-10': ('PARTIAL', 4, 4, 'UNVERIFIED', 'Existing single-header source path remains; no empty-project macOS render evidence.'),
    'AUD-11': ('PARTIAL', 5, 5, 'UNVERIFIED', 'DOM and AI modes are separate; AI candidates now pass strict vendor validation and remain unselectable until DOM verification.'),
    'AUD-12': ('PARTIAL', 4, 4, 'UNVERIFIED', 'Send path is fail-closed on injection and remote-chat binding; real WebKit response remains unverified.'),
    'AUD-13': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Exact model/effort injection, unsupported-model effort gating and one-shot refresh retry are implemented; live confirmation remains unverified.'),
    'AUD-14': ('PARTIAL', 4, 4, 'UNVERIFIED', 'System prompt preamble path remains; remote target observation remains unverified.'),
    'AUD-15': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Strict DOM candidates, two-level fingerprinted expansion and Qwen Coder regression pass; live vendor DOM remains unverified.'),
    'AUD-16': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Per-model effort/profile status and selector hiding are explicit; live Kimi/Qwen controls remain unverified.'),
    'AUD-17': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Model/Model Comparison/effort noise is rejected by strict vendor grammar and regression tests; live DOM remains unverified.'),
    'AUD-18': ('PARTIAL', 5, 5, 'UNVERIFIED', 'active/inactive/unsupported/notDetected/error plus isSelectable and unavailable-row removal are implemented; live UI remains unverified.'),
    'AUD-19': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Full-width persistent accordion renders every discovered row with no prefix(8); macOS visual interaction remains unverified.'),
    'AUD-20': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Full row click selects and Select/Выбрать was removed from menu; macOS hit behavior remains unverified.'),
    'AUD-21': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Profile values/labels are shown in settings and overrides remain separate; live controls remain unverified.'),
    'AUD-22': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Typed pre-send injection failure aborts, refreshes same page once and retries same remote chat without duplicate send; WebKit failure trigger remains unverified.'),
    'AUD-23': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Named persistence plus sessionID-keyed browser pool and post-login refresh use the new account; real two-account switching remains unverified.'),
    'AUD-24': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Project/local-chat/provider/session pool key plus remote mapping isolate contexts; real provider page behavior remains unverified.'),
    'AUD-25': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Remote UUID mapping is persisted and journaled with migration-safe tests; live provider URL verification remains unverified.'),
    'AUD-26': ('PARTIAL', 5, 5, 'UNVERIFIED', 'New local mapping calls exact New Chat and blocks if URL/UUID does not change; live subagent/provider behavior remains unverified.'),
    'AUD-27': ('PARTIAL', 5, 5, 'UNVERIFIED', 'send_started/completed/failure journal records include remoteChatID plus local routing fields; live send remains unverified.'),
    'AUD-28': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Existing mapping navigates by verified URL/UUID and fails closed on mismatch; live conversation switch remains unverified.'),
    'AUD-29': ('PARTIAL', 4, 5, 'UNVERIFIED', 'Requested direct accordion/row/menu semantics are now represented in source; target visual review remains unverified.'),
    'AUD-30': ('FAIL', 1, 0, 'FAIL', 'Linux cannot build SwiftUI/AppKit target; macOS build-app.sh and tests still require user Mac.'),
    'AUD-31': ('PARTIAL', 5, 5, 'UNVERIFIED', 'Round 46 updates this matrix/report with evidence boundaries; target runtime rows remain unverified by design.'),
    'AUD-32': ('PARTIAL', 4, 4, 'UNVERIFIED', 'Adversarial contract, source checks and 68-test Foundation retest are added; manual macOS acceptance remains outstanding.'),
}

with path.open(newline='') as f:
    rows = list(csv.DictReader(f))
    fields = rows[0].keys()
for row in rows:
    if row['id'] in score_updates:
        status, impl, fit, runtime, finding = score_updates[row['id']]
        row['implementation_status'] = status
        row['implementation_quality_0_5'] = str(impl)
        row['task_fit_quality_0_5'] = str(fit)
        row['target_runtime_status'] = runtime
        row['acceptance_finding'] = finding
with path.open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    writer.writerows(rows)
print(f'updated {len(score_updates)} rows')
