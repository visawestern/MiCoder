# EVAL DEFINITION: harness-tax (Фаза 3)

Методология: Arena HarnessTax + harness-guide-2026 (KDD Scaffold Effect).
Цель: доказать, что `minimal`-профиль держит success ±2% от `full` при кратно меньшей цене,
и сделать `minimal` дефолтом.

## Capability evals

- [ ] **C1 — учёт цены терна**: каждый агентный виток пишет
      `promptTokens / completionTokens / costUSD / initialContextBytes / profile`;
      нулевые захваты не создают точек (существующее правило `UsageCapture.isZero`).
- [ ] **C2 — профили харнесса**: `minimal (core 5 тулов, короткие схемы)` /
      `standard (+grep/glob/todo)` / `full (все 19)`; профиль пишется в каждую точку.
- [ ] **C3 — idle-killer метрика**: счётчик холостых шагов
      (повторный read одного файла / 3-й одинаковый вызов); виток сверх капа 40 — early-stop.
- [ ] **C4 — отчёт**: `success + cost + turns + initialBytes` по профилям
      на 15–30 задачах из `docs/FEATURE_SPREADSHEET.csv` × 3 повтора, CI бутстрепом.

## Regression evals (каждый прогон — pass^3 = 100%)

- [ ] Существующие `UsageStatisticsAggregatorTests` зелёные.
- [ ] `E13E21 / ProjectDatabaseManager / AgentResourceInstaller` suites зелёные
      (инструментация не трогает пути/реестры).
- [ ] Нулевые/отрицательные/NaN costs по-прежнему не презентуются как деньги
      (`UsageCostSafety.sanitized`).

## Метрики релиза

- `pass@3 >= 0.90` на capability; success(minimal) в пределах ±2% от success(full);
  cost(full)/cost(minimal) зафиксирован как текущий налог (ожидаем 1.5–2× по Arena).

## Baseline (до имплементации)

- Текущий харнесс = всегда `full`: 19 тулов в преамбуле + 20 тернов истории,
  без бюджета, без капа витков, без idle-детекта, без разреза по профилям.

Статус: DEFINED, ждёт TDD-имплементации C1→C4 по одному.
