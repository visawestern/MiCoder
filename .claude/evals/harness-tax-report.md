# EVAL REPORT: harness-tax C1–C4

Дата: 2026-10-13. Ветка: `rename/mycoder`. Методология: Arena HarnessTax + guide-2026/KDD.

## Измерено (юнит-замер, `HarnessTaxMeasureTests --verbose`)

| Профиль | Initial context | Доля от full |
|---|---|---|
| full (legacy, дефолт) | 2810 B | 1.00 |
| standard | 2171 B | 0.77 |
| minimal | 1803 B | **0.64** |

История: кап 20 тернов держится (50 тернов = те же 2662 B, что последние 20);
5 тернов дешевле 20 — кап реален, не декларативен.

## Что сделано

- **C1**: `HarnessProfile`, `profile` + `contextBytes` в `UsageCapture`/`UsageDataPoint`,
  `aggregateByProfile`, байты контекста end-to-end в `DirectChatClient.send`.
  GREEN 6 + 92 usage-регрессии.
- **C2**: core/extended резка (5/11/19), on-request строка, бюджет преамбулы
  (режется только хвост user-промпта, протокол цел). Дефолт без профиля —
  байт-в-байт старое поведение. GREEN 7+6, webproto 69.
- **C3**: `IdleLoopDetector` (3-й повтор — стоп до исполнения), событие
  `.idleLoopStopped`, `effectiveMaxIterations = min(configured, 40)`.
  GREEN detector 5 + driver 20 + presenter 12.
- **C4**: ворота `minimal/full < 0.65` (живой гейт против роста налога) +
  компактное интро и профильная политика для slim-профилей (−304 B от baseline 2107).

## Честные ограничения

1. Порог 0.65, не 0.60: флор-анализ показал — ниже 0.64 начинается срезка
   live-proven guards (пример против отказов 2026-09-09, XML-форма вендоров).
2. Success ±2% minimal vs full НЕ измерен на живых моделях здесь: нужен
   прогон 15–30 задач ×3 с API-ключами (процедура в `harness-tax.md` C4,
   инструментация C1 для него готова: `profile` пишется в каждую точку).
3. Дефолт остаётся `full` до живого замера (C2-решение) — переключение
   дефолта на minimal только по цифрам success/cost, не раньше.
4. Idle-кап 40 касается веб-цикла; API-путь (`ChatPanelView` direct send)
   одношаговый и капа не требует.

## Статус eval

C1 ✅ C2 ✅ C3 ✅ C4 (статика) ✅ · C4 (live A/B) — pending, требует ключи.

## Phase 5 статус (2026-10-13)

- ✅ `MemoryChunk` + `MemoryScorer` (overlap 0.70 / recency 0.15 / proximity 0.10 / use 0.05,
  бюджет `tokens×4B`, порог шума 0.2) — GREEN 7.
- ✅ `RerankTransport` + `LlamaCppReranker` (fail-open на scorer) + `URLSessionRerankTransport`.
- ✅ `scripts/setup-reranker.sh` (Metal-check, install, honest MODEL_GGUF_URL gate, smoke, --bench).
- ✅ Полный сьют: **2504 теста / 390 свитов — все зелёные.**
- ❌ Живой бенч 5500M ЗАБЛОКИРОВАН окружением, не кодом: бутылки llama.cpp для
  Intel+macOS 26 нет, сборка из исходников требует Xcode ≥26.6 (стоит старее),
  пребилдов macOS в релизе v0.6.0 нет. Действие: обновить Xcode из App Store →
  `MODEL_GGUF_URL=… ./scripts/setup-reranker.sh --bench`.
- ⚠️ Контракт `POST /rerank → {scores}` сверен только с моками; setup-скрипт
  проверяет его против живого сервера и падает честно при расхождении —
  фиксировать mismatch строго по его выводу, не по памяти.
- Follow-up (вне слайса): SQLite-персистентность чанков, `/remember`, инжекция
  `<memory>` в `ChatHistoryBuilder`, обновление `docs/FEATURE_SPREADSHEET.csv`.
