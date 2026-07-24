#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# logic-harness.sh — Ground-truth Foundation-only test harness (Swift on Linux)
#
# MiCoder's app target imports SwiftUI/AppKit/WebKit and CANNOT compile on Linux.
# This harness compiles ONLY the Foundation-only Services/Models and runs their
# swift-testing suites, producing a REPRODUCIBLE @Test / pass / fail count in
# EVAL.md — the one number every doc should cite instead of a hand-typed guess.
#
# Unlike the legacy scripts/test-logic.sh (which hard-coded a whitelist and a
# stale repo path), this AUTO-DISCOVERS every *.swift under Sources that imports
# only Foundation (no SwiftUI/AppKit/WebKit/SQLite/Cocoa) and every test file that
# does the same, so coverage tracks the tree instead of drifting from it.
#
# Usage: scripts/logic-harness.sh        (run from repo root; writes ./EVAL.md)
# ═══════════════════════════════════════════════════════════════════════════
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
EVAL="$REPO/EVAL.md"
SWIFT_VER="6.0.3"
UBUNTU="ubuntu24.04"

log() { echo "━━━ $*"; }

# ── 1. Ensure a Swift toolchain ─────────────────────────────────────────────
if ! command -v swift >/dev/null 2>&1; then
  log "Swift not found — installing Swift $SWIFT_VER for $UBUNTU"
  TARBALL="swift-${SWIFT_VER}-RELEASE-${UBUNTU}"
  URL="https://download.swift.org/swift-${SWIFT_VER}-release/${UBUNTU//./}/swift-${SWIFT_VER}-RELEASE/${TARBALL}.tar.gz"
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y --no-install-recommends \
    binutils git libc6-dev libcurl4-openssl-dev libedit2 libgcc-s1 \
    libpython3-dev libsqlite3-0 libstdc++6 libxml2-dev libz3-dev \
    pkg-config tzdata unzip zlib1g-dev curl ca-certificates >/dev/null 2>&1 || true
  mkdir -p /opt/swift
  if curl -fsSL "$URL" -o /tmp/swift.tar.gz; then
    tar -xzf /tmp/swift.tar.gz -C /opt/swift --strip-components=1
    export PATH="/opt/swift/usr/bin:$PATH"
  else
    log "❌ Could not download Swift toolchain from $URL"
    exit 3
  fi
fi
log "Using $(swift --version 2>&1 | head -1)"

# ── 2. Assemble an ephemeral Foundation-only package ────────────────────────
PKG="${TMPDIR:-/tmp}/micoder-logic-harness"
rm -rf "$PKG"
mkdir -p "$PKG/Sources/MiCoderLogic" "$PKG/Tests/MiCoderLogicTests"
cp -r "$REPO/MiCoder/Sources/Resources" "$PKG/Sources/MiCoderLogic/Resources" 2>/dev/null || true

# A file is Foundation-only if it does NOT import a macOS-only framework.
is_foundation_only() {
  ! grep -Eq '^[[:space:]]*(import|#if canImport\()[[:space:]]*(SwiftUI|AppKit|WebKit|Cocoa|SQLite)\b' "$1"
}

# Test-only stub for PlusMenuItem (the real one carries UI deps).
cat > "$PKG/Sources/MiCoderLogic/PlusMenuItemStub.swift" <<'STUB'
import Foundation
enum PlusMenuItem: String, CaseIterable, Equatable {
    case addAttachment, addPhoto, insertMention, insertCommand, insertSession
}
STUB

src_count=0
for f in "$REPO"/MiCoder/Sources/Services/*.swift "$REPO"/MiCoder/Sources/Models/*.swift; do
  [ -e "$f" ] || continue
  if is_foundation_only "$f"; then
    ln -sf "$f" "$PKG/Sources/MiCoderLogic/$(basename "$f")"
    src_count=$((src_count + 1))
  fi
done

test_count_files=0
for f in "$REPO"/MiCoder/Tests/*.swift; do
  [ -e "$f" ] || continue
  if is_foundation_only "$f"; then
    ln -sf "$f" "$PKG/Tests/MiCoderLogicTests/$(basename "$f")"
    test_count_files=$((test_count_files + 1))
  fi
done

cat > "$PKG/Package.swift" <<'PKGEOF'
// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "MiCoder",
    platforms: [.macOS(.v13)],
    products: [.library(name: "MiCoder", targets: ["MiCoder"])],
    targets: [
        .target(name: "MiCoder", path: "Sources/MiCoderLogic", resources: [.process("Resources")]),
        .testTarget(name: "MiCoderTests", dependencies: ["MiCoder"], path: "Tests/MiCoderLogicTests")
    ]
)
PKGEOF

log "Discovered $src_count Foundation-only source files, $test_count_files test files"

# ── 3. Build + test, capturing output ───────────────────────────────────────
cd "$PKG"
LOG="${TMPDIR:-/tmp}/micoder-harness.log"
log "swift test --no-parallel"
set +e
swift test --no-parallel 2>&1 | tee "$LOG"
TEST_RC=${PIPESTATUS[0]}
set -e 2>/dev/null || true

# ── 4. Parse results ────────────────────────────────────────────────────────
# swift-testing prints e.g. "Test run with 1234 tests passed after ..." or
# "... N tests failed". Fall back to counting @Test declarations if unparsed.
DECLARED=$(grep -rhoE '@Test\b' "$PKG/Tests" | wc -l | tr -d ' ')
SUITES=$(grep -rhoE '@Suite\b' "$PKG/Tests" | wc -l | tr -d ' ')
PASSED=$(grep -oE 'with [0-9]+ test[s]? passed' "$LOG" | grep -oE '[0-9]+' | tail -1)
FAILED=$(grep -oE '[0-9]+ test[s]? failed' "$LOG" | grep -oE '[0-9]+' | tail -1)
EXECUTED=$(grep -oE 'with [0-9]+ test' "$LOG" | grep -oE '[0-9]+' | tail -1)
[ -z "${PASSED:-}" ] && PASSED="?"
[ -z "${FAILED:-}" ] && FAILED="0"
[ -z "${EXECUTED:-}" ] && EXECUTED="?"

if [ "$TEST_RC" -eq 0 ]; then VERDICT="✅ PASS"; else VERDICT="❌ FAIL (rc=$TEST_RC)"; fi

# ── 5. Emit EVAL.md ─────────────────────────────────────────────────────────
cat > "$EVAL" <<EOF
# EVAL — MiCoder Foundation-only logic harness

**Verdict:** $VERDICT
**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ") by \`scripts/logic-harness.sh\`
**Swift:** $(swift --version 2>&1 | head -1)

## Ground-truth numbers (reproducible)

| Metric | Value |
|--------|-------|
| Foundation-only source files compiled | $src_count |
| Foundation-only test files run | $test_count_files |
| \`@Test\` declarations (this harness scope) | $DECLARED |
| \`@Suite\` declarations (this harness scope) | $SUITES |
| Tests executed (runtime, incl. parameterized) | $EXECUTED |
| Tests passed | $PASSED |
| Tests failed | $FAILED |

## Scope & honest limits

- The macOS app target (SwiftUI/AppKit/WebKit/SQLite) is **not** compiled here —
  it cannot build on Linux. This harness covers the pure logic only.
- Coverage is **auto-discovered** (every Foundation-only file under Sources/Tests),
  not a hand-maintained whitelist, so it tracks the tree.
- This is the ONLY reproducible test number for the project. Any documentation
  count that disagrees with this file is stale.

## Tail of test output

\`\`\`
$(tail -25 "$LOG")
\`\`\`
EOF

log "Wrote $EVAL (verdict: $VERDICT)"
exit "$TEST_RC"
