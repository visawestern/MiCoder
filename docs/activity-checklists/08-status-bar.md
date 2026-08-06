# Чеклист: Строка состояния (StatusBarView.swift)

Источник: `MiCoder/Sources/Views/StatusBarView.swift`. Ручная сверка кода:
2026-08-06; `swift test` — 1716/1716 PASS.

| № | Элемент / состояние | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Индикатор подключения | Зелёная точка и «Connected» при `serverConnected`, красная и «Disconnected» иначе. | ✅ |
| 2 | Текущая модель | Показать CPU-chip только если `selectedModel` не пуст. | ✅ |
| 3 | Idle | Показать локализованную строку idle, когда нет loading/streaming. | ✅ |
| 4 | Processing | При `isLoading` показать spinner и локализованную строку processing. | ✅ |
| 5 | Generating | При `isStreaming` показать spinner и generating; это состояние приоритетнее loading. | ✅ |
| 6 | Host:port | При подключении показать network-chip с `serverHost:serverPort`; при отключении скрыть. | ✅ |

## Риск live-QA

- ⚠️ Контраст цветов статусов и локализацию всех трёх строк нужно подтвердить на реальных светлой и тёмной темах.

## Цепочная проверка PASS

Все ветви `StatusBarView.body` вручную прослежены от AppState до результата
рендера и покрыты повторным полным `swift test`. Детали:
[`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
