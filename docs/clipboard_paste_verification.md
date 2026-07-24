# Clipboard Paste Verification

**Date:** 2026-06-21  
**Status:** PASS

## Summary

Clipboard paste for message attachments was refactored to a single path:

- `MessageAttachmentStore` — `@MainActor` source of truth for `attachedImages` / `attachedFiles`
- `PasteboardAttachmentDetector` — unified pasteboard type detection shared by UI and `ClipboardProvider`
- `ChatAttachmentBridge` — one window-level ⌘V monitor
- `messageAttachmentImportZone` — paste + drop on the full input card (`CenteredInputCard`, `BottomInputBar`)
- `PasteAwareMessageTextField` — AppKit wrappers with strong store reference and scroll-view paste helper

## Automated verification

```bash
./scripts/verify_clipboard_paste.sh
```

| Step | Result |
|------|--------|
| `swift test` (339 tests) | PASS |
| `AutomatedClipboardImportTests` — synthetic screencapture pasteboard (PNG + Apple PNG + TIFF) | PASS |
| `PasteboardAttachmentDetectionTests` — detect/consume contract + stale file URL + inline bytes | PASS |
| `PasteRoutingIntegrationTests` — text view, scroll view, bridge routing, Edit Paste | PASS |
| `LiveClipboardProbeTests` — live pasteboard consume + store import | PASS |

### Synthetic pasteboard types exercised

- `public.png`
- `Apple PNG pasteboard type`
- `public.tiff`
- `NeXT TIFF v4.0 pasteboard type`

`ClipboardProvider.consume()` returns one image with base64 length > 20; `MessageAttachmentStore.importFromPasteboard()` sets `attachedImages.count == 1`.

## Live probe notes

In headless/CI environments `screencapture -c` may fail (`could not create image from display`). The verify script falls back to seeding the general pasteboard with the same multi-type layout used by macOS screenshots, then runs `MIMO_CLIPBOARD_PROBE=1 swift test --filter LiveClipboardProbeTests`.

On a machine with Screen Recording permission, run:

```bash
screencapture -c -x
MIMO_CLIPBOARD_PROBE=1 swift test --filter LiveClipboardProbeTests
```

Expected: `consume()` non-empty, base64 length > 100, store import succeeds.

## Manual checklist

1. Empty chat: ⌘V after screenshot → strip shows **1 photo**
2. Active chat bottom bar: same
3. Click input area then ⌘V (toolbar had focus) → strip via `ChatAttachmentBridge`
4. Drag PNG from Finder onto input card → strip appears
5. Sidebar search field: ⌘V inserts text (paste **not** intercepted)
6. Edit → Paste with screenshot in clipboard → strip appears
7. Empty clipboard paste → brief error banner under input
8. Paste image-only without model → strip visible, Send disabled until model selected
9. Send image message → user row shows thumbnail; reload session → image persists if server returns `type:image` parts

## Manual repro 2026-06-21

Baseline `./scripts/verify_clipboard_paste.sh` **PASS** (339 unit tests). Live probe **PASS**.  
Automated routing matrix covers scenarios 1–6 and 8 via `PasteRoutingIntegrationTests`.  
Scenario 7 (empty clipboard banner) covered by `MessageAttachmentStoreTests`.  
Scenario 9 (history reload) covered by `MessageStoreTests.messageFromServerRestoresImages`.

**Diagnosis:** clipboard consume/store layer was healthy; fixes targeted paste routing (strong store ref, unified detector, inline-bytes-before-file-URL consume order, scroll-view import helper, `MimoMessagePart.image` decode).

## Architecture

```
⌘V / Edit Paste / Drop / onPasteCommand
        → ChatAttachmentBridge / AttachmentPasteTextView / import zone
        → PasteboardAttachmentDetector.hasAttachments()
        → MessageAttachmentStore.importFromPasteboard()
        → ImagePreviewStrip + AttachedFilesStrip
        → MessagePartsBuilder → POST /session/{id}/message (type:image base64)
```

Paste works independently of Send readiness (provider/model); Send button may stay disabled while the preview strip is visible.
