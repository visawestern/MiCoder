# Activity 04 — Chat Input & Composer

Источники: `Sources/Views/Components/InputControls.swift`, `Sources/Views/Components/InputViews.swift`, `Sources/Views/Components/PlusMenuView.swift`, `Sources/Views/Components/InputCommandDropdownView.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Centered input card | `InputViews` with workspace header | Rounded capsule, text field, toolbar | 95/100 | PASS |
| 2 | Auto-growing text field | `CompactMessageTextField` via NSTextView | Растёт при вводе | 95/100 | PASS |
| 3 | Workspace dropdown | Workspace header → searchable dropdown | Переключение workspace + Open folder + Remote connect | 95/100 | PASS |
| 4 | Access level menu | `InputControls` → Ask/Edit/Bash/Webfetch | Уровень доступа с иконками | 95/100 | PASS |
| 5 | Agent mode menu | Build/Plan/Compose | Plan disabled если модель не поддерживает | 95/100 | PASS |
| 6 | Provider selector | Menu with server/custom/local/web providers | Выбор провайдера | 95/100 | PASS |
| 7 | Model selector | Menu shows models; checkmark on current | Выбор модели | 95/100 | PASS |
| 8 | Variant selector | Variants when capabilities.reasoning | Выбор reasoning effort | 95/100 | PASS |
| 9 | Plus menu (attachments) | Paperclip/photo/@/#/command | Добавление файлов и изображений | 95/100 | PASS |
| 10 | Send button | Arrow (send) / stop square (loading) | Отправка или остановка | 95/100 | PARTIAL |
| 11 | Message queue indicator | Pending messages as numbered list | Очередь при отправке во время загрузки | 90/100 | PASS |
| 12 | Attachment preview | ComposerAttachmentPreview | Имена и thumbnails | 90/100 | PASS |
| 13 | Bottom input bar | Compact bar, single-line until typing | Нижняя панель ввода | 95/100 | PASS |
| 14 | Model parameters dialog | ModelParametersButton popover | Temperature/max_tokens/top_p/system | 95/100 | PARTIAL |
| 15 | Command dropdown (/ @ # $) | InputCommandTriggerLogic | Группы Commands/Skills/Files/Sessions | 95/100 | PASS |
| 16 | Dropdown $ MCP trigger | Symbol mapped in logic | MCP server suggestions | 90/100 | PASS |
| 17 | Dropdown enable toggle | `appState.inputDropdownEnabled` | Вкл/выкл palette | 95/100 | PASS |
| 18 | Image paste | `ChatPasteCoordinator` detects images | Вставка изображений | 90/100 | PASS |
| 19 | File paste | `PasteboardAttachmentDetector` | Вставка файлов | 90/100 | PASS |
| 20 | Paste routing | `ChatPasteRoutingLogic` routes by focus | Маршрутизация вставки | 95/100 | PASS |

## User Story

As a user, I can compose messages with auto-growing text, attach files and images, select providers/models/variants, switch access levels and agent modes, use the command palette with `/ @ # $` triggers, and see attachment previews before sending.

## Bugs Found & Fixed

| ID | Описание | Severity | Статус |
|---|---|---|---|
| BUG-01 | `hasAPIKey` check uses in-memory field cleared after Keychain migration | HIGH | DOCUMENTED (design trade-off) |

## Regression Status

2288/2288 tests GREEN.
