# Activity 33 — Message History Tail Paging

Дата аудита: 2026-09-06
Код: `DatabaseBridge.swift:400-423` (`loadMessageTail`, `loadOlderPage`), `MessageHistoryPaginationLogic.swift`, commit 00f8781

## Обнаруженные кнопки/действия/состояния

| # | Поведение | Текущее качество |
|---|---|---|
| 1 | Первичная загрузка истории — newest-first tail (ASC после fetch) | WORKS |
| 2 | Локальный paging старых сообщений по кнопке | WORKS (loadOlderPage) |
| 3 | `hasMore` корректно сигнализирует наличие более старых | WORKS (offset > 0) |
| 4 | Стартовый limit не скрывает новые сообщения после роста сессии | WORKS (tail = total - bounded; это был исходный баг — старая схема скрывала всё после page size) |
| 5 | bounded = min(max(take,0), total) — edge: take=0 → [] без SQL | WORKS |
| 6 | olderCount <= 0 → ([], false) | WORKS |

## User Stories

### US-HP-01: История загружается с конца
**User story:** Как пользователь с длинной сессией, я хочу сразу видеть последние сообщения, а старые подгружать по необходимости.
**Ожидаемое поведение:** initial load = tail N; кнопка старше подгружает страницу перед показанными; hasMore до начала.
**Тест:** `Round30MessageUpsertTests`, `MessageHistoryPaginationLogic` тесты (commit 00f8781). GREEN.

## Математическая инвариантность
- `loadMessageTail(take)`: offset = total - bounded — инвариант "последние take в ASC" соблюдается при любом total ≥ 0.
- `loadOlderPage`: offset = olderCount - take, hasMore = offset > 0 — monotonic, no overlap/no gap с loaded tail (olderCount = total - loadedCount).
- До фикса (commit 00f8781): oldest-first + limit → новые сообщения invisible после роста. Корректная модель заменила дефектную.
