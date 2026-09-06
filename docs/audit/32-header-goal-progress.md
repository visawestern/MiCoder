# Activity 32 — Header Goal Progress

Дата аудита: 2026-09-06
Код: `MiCoder/Sources/Services/HeaderGoalProgressLogic.swift`, `TopBarView.swift` (diff commit 10a8932)

## Обнаруженные кнопки/действия/состояния

| # | Поведение | Текущее качество |
|---|---|---|
| 1 | Топ-бар показывает текущую цель сессии | WORKS (SessionGoalLogic.badgeLabel) |
| 2 | Прогресс `n/m` из currentSteps (TodoWrite/markdown checklist/step markers) | WORKS (TaskProgress(steps:).formatted) |
| 3 | Badge скрывается, если нет ни цели, ни шагов | WORKS (shouldShow: session + goal|steps) |
| 4 | Прогресс-фракция для ProgressView | WORKS (progressFraction, 0...1) |
| 5 | Иконки статусов шагов (SF Symbols) | WORKS (stepIconName) |
| 6 | MaxLength 40 для badge | WORKS (параметр) |

## User Stories

### US-HG-01: Цель сессии в топ-баре
**User story:** Как пользователь, я хочу видеть текущую цель сессии и живой прогресс шагов.
**Ожидаемое поведение:** Badge = "🎯 <goal>  n/m"; без шагов — просто goal; без goal но со шагами — прогресс; без сессии — скрыт.
**Тест:** `HeaderGoalProgressLogicTests` (53 строки, commit 10a8932). GREEN.

## Архитектурная оценка
- Чистое разделение: логика (enum) vs TopBarView (rendering) — правильная модель.
- Нет смешения ответственности, состояние (steps) приходит извне; source of truth — `currentSteps` execution step sync.
