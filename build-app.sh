#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# build-app.sh — Build MiCoder.app with automatic version bump.
#
# Produces MiCoder.app in the REPO ROOT (not hidden in .build/), copying the
# SPM-generated resource bundles so Skills/MCP catalogs load. Full compiler
# output is shown on failure — no truncation, no guesswork.
#
# Usage:
#   ./build-app.sh              # bump + test + build + bundle
#   ./build-app.sh --skip-tests # bump + build + bundle (skip tests)
#   ./build-app.sh --no-bump    # don't bump the version
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="MiCoder"          # SPM executable target/product name
APP_BUNDLE="MiCoder.app"      # user-facing bundle name (in repo root)
BUILD_DIR=".build/release"
RESOURCES_DIR="MiCoder/Resources"
INFO_PLIST="$RESOURCES_DIR/Info.plist"

SKIP_TESTS=0
DO_BUMP=1
for arg in "$@"; do
    case "$arg" in
        --skip-tests) SKIP_TESTS=1 ;;
        --no-bump)    DO_BUMP=0 ;;
        *) echo "Unknown option: $arg"; exit 2 ;;
    esac
done

# ── Version bump ─────────────────────────────────────────────
SHORT_VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "0.0")
BUILD_NUM=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "0")
echo "━━━ Current: v$SHORT_VER (build $BUILD_NUM)"

if [ "$DO_BUMP" -eq 1 ]; then
    MAJOR="${SHORT_VER%%.*}"; REST="${SHORT_VER#*.}"; MINOR="${REST%%.*}"
    NEW_SHORT="${MAJOR}.$((MINOR + 1))"
    NEW_BUILD=$((BUILD_NUM + 1))
    echo "━━━ Bumping to v$NEW_SHORT (build $NEW_BUILD)"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_SHORT" "$INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$INFO_PLIST"
else
    NEW_SHORT="$SHORT_VER"; NEW_BUILD="$BUILD_NUM"
fi

# ── Tests (optional — never block a build check) ─────────────
if [ "$SKIP_TESTS" -eq 1 ]; then
    echo "━━━ Skipping tests (--skip-tests)"
else
    echo "━━━ Running tests… (failures are reported but do NOT abort the build)"
    if swift test; then
        echo "━━━ Tests passed."
    else
        echo "━━━ ⚠️  Tests failed — continuing to build anyway (see output above)."
    fi
fi

# ── Build release (FULL output; abort with a clear message on failure) ──
echo "━━━ Building release…"
if ! swift build -c release --product "$APP_NAME"; then
    echo ""
    echo "━━━ ❌ BUILD FAILED. Full compiler output is above (not truncated)."
    echo "━━━    Fix the errors and re-run ./build-app.sh"
    exit 1
fi

# ── Assemble the .app bundle in the repo root ────────────────
echo "━━━ Assembling $APP_BUNDLE (clean)…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$INFO_PLIST" "$APP_BUNDLE/Contents/Info.plist"
[ -f "$RESOURCES_DIR/AppIcon.icns" ] && cp "$RESOURCES_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# SPM packages resources (catalogs, skill markdown) into <Target>_<Product>.bundle.
# Without copying these the packaged app shows "resource catalog is missing".
echo "━━━ Copying resource bundles…"
shopt -s nullglob
copied=0
for b in "$BUILD_DIR"/*.bundle; do
    cp -R "$b" "$APP_BUNDLE/Contents/Resources/"
    echo "    + $(basename "$b")"
    copied=$((copied + 1))
done
shopt -u nullglob
[ "$copied" -eq 0 ] && echo "    (no SPM resource bundles found — catalogs may not load)"

BIN_SIZE=$(stat -f "%z" "$BUILD_DIR/$APP_NAME" 2>/dev/null || stat --format="%s" "$BUILD_DIR/$APP_NAME" 2>/dev/null || echo "0")
echo "━━━ ✅ Built v$NEW_SHORT (build $NEW_BUILD) — $((BIN_SIZE / 1024)) KB"
echo "━━━ App: $SCRIPT_DIR/$APP_BUNDLE"
echo "━━━ Run: open '$APP_BUNDLE'"
