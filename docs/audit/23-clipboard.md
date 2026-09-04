# Activity 23 — Clipboard (Paste/Drop)

Источники: `Sources/Services/ChatPasteCoordinator.swift`, `Sources/Services/ClipboardPasteLogic.swift`, `Sources/Services/PasteboardAttachmentDetector.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Image paste | `ChatPasteCoordinator` detects images | Вставка изображений | 90/100 | PASS |
| 2 | File paste | `PasteboardAttachmentDetector` detects file URLs | Вставка файлов | 90/100 | PASS |
| 3 | Paste routing | `ChatPasteRoutingLogic` routes by focus | Маршрутизация вставки | 95/100 | PASS |

## User Story

As a user, I can paste images and files from clipboard, and the paste is routed to the correct text field based on focus.
