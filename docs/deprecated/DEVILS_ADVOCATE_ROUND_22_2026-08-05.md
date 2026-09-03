# Devil's Advocate — Round 22 (2026-08-05)

Тема раунда: **E23/E24 — автоопределение локального провайдера (Раздел 9 п.30/п.33/п.34)**.
Ручная пошаговая проверка цепочки «зондирование → классификация → подтверждение → конфиг → маршрутизация отправки» как адвокат дьявола; TDD red→green на найденные дефекты.

---

## Найденные проблемы (каждая проверена вручную по коду, file:line)

### F1 (HIGH) — E24: общий таймаут ограничивал только СТАРТ пробы, а не её ДЛИТЕЛЬНОСТЬ
**Где:** `ProviderAutoDetector.detect` — проверка `deadlinePassed(deadline)` стояла перед каждым `probe.get(...)`, но сам `probe.get` ничем не ограничивался сверху.
**Почему это реально:** худший случай для живого `URLSessionProviderProbe` = 4 × `stepTimeout`(2с) = 8с, а дефолтный `overallTimeout` = 10с > 8с → **дедлайн на реальном пути никогда не срабатывал** (мёртвый код). Комментарий «не может растянуть зондирование до полного 4 × stepTimeout» был ложным — именно столько оно и занимало.
**Красный тест:** `hangingProbeCancelledAtDeadline` — проба спит 3с при бюджете 0.25с. На старом коде: `wasCancelled == false`, `elapsed = 3.0s > 2.5s` (падение ровно по заявленному дефекту).
**Решение:** жёсткий дедлайн — каждая проба гоняется против таймера оставшегося бюджета (`probeOnce`), проигравшая сторона отменяется; `URLSessionProviderProbe` стал отменяемым (`withTaskCancellationHandler` + thread-safe holder для `URLSessionDataTask`). Теперь последовательность гарантированно ≤ `overallTimeout`, а зависшая проба отменяется на дедлайне.
**Зелёный тест:** тот же тест проходит за **0.252с** (было 3.0с).

### F2 (MED) — E23: статусная строка врала после отмены
**Где:** `SettingsView.runAutoDetect/confirmPendingDetection` — после детекта писалось «Detected: X, N models.», и строка НЕ менялась ни при подтверждении, ни при отмене. Пользователь, нажавший «Отмена», видел «Обнаружен…», как будто провайдер был добавлен.
**Решение:** новый тестируемый слой `AutoDetectStatusText` (detected/confirmed/cancelled/nothing/invalid) + проводка в view: cancel → «Detection cancelled — nothing was added.», confirm → «Added: … at host:port.»; строка «detected» теперь явно просит подтверждение («Confirm to add.»).

### F3 (HIGH) — E23: обнаруженный ACP-сервер сохранялся как OpenCode и не мог отправлять
**Где:** `LocalProviderConfirmLogic.config` — `.acp → .openCode`; `SendRouteResolver` — `.openCode` маршрутизируется в `http://host:port/v1/chat/completions` (OpenAI-контракт), который реальный ACP-сервер (протокол `/acp/v1`) не обслуживает. Дополнительно: кейс `SendRoute.acp` в резолвере вообще не потреблялся send-путём (`ChatPanelView` проверял только `isSelectedACPProvider` для custom-провайдеров) — «мёртвый» маршрут.
**Решение:**
- `LocalProviderKind` получил честный кейс `.acp` (displayName «ACP», icon, `defaultPort 8080`, `healthPath "/models"`);
- `LocalProviderConfig.apiBaseURL` для ACP = `http://host:port/acp/v1` (ACPClient дописывает `chat/completions`);
- `SendRouteResolver`: `.acp` локальный провайдер → `SendRoute.acp`;
- `ChatPanelView`: ACP-ветка теперь потребляет маршрут `.acp` (локальные ACP-провайдеры строят `ACPClient` из `apiBaseURL`), custom-путь сохранён.

### F5 (MED) — Раздел 9 п.34: предупреждение о не-локальном адресе стиралось до показа
**Где:** `runAutoDetect` — `detectResult = "Warning: …"` затем сразу `detectResult = ""` перед стартом Task → предупреждение (требование п.34: «Вы уверены, что это ваш локальный сервер?») **никогда не отображалось**.
**Решение:** warning вычисляется заранее и компонуется с результатом детекта в одну статусную строку; проверено тестами `warningForNonLocal` (203.0.113.7 → warning; localhost/127.0.0.1/192.168.x → nil).

### F4 (LOW, зафиксировано) — локализация UI автоопределения
Все строки `LocalProvidersSection` (включая новые) — хардкод-английский; план Раздел 2/п.39 требует 10 языков. Тесты привязаны к английским строкам. Не фиксировалось в этом раунде (масштаб — отдельная локализационная итерация по Разделу 2); открытый пункт.

---

## TDD: red → green

| Тест | Red (до фикса) | Green (после) |
|------|----------------|---------------|
| `hangingProbeCancelledAtDeadline` | ✘ 3.0s, `wasCancelled=false`, `elapsed 3.0>2.5` | ✔ 0.252s, cancelled, 1 проба |
| `zeroTimeoutAttemptsNoProbes` | ✔ (guard) | ✔ |
| `negativeTimeoutAttemptsNoProbes` | ✔ (guard) | ✔ |
| `acpDetectionMapsToAcpKind` | ✘ (старое поведение: .openCode) | ✔ .acp + `/acp/v1` |
| `allDetectedKindsMapSensibly` | — (новые символы) | ✔ |
| `acpLocalProviderRoutesToACP` | — | ✔ `route == .acp` |
| `nonACPLocalsStillRouteOpenAICompatible` | — | ✔ `/v1` |
| `duplicateHostPortIsDetected` | — | ✔ |
| `nonLocalHostWarning` / `cancelledStatusText` / `confirmedStatusText` / `detectedStatusTextAsksToConfirm` / `invalidAddressStatusText` | — | ✔ |

Полный прогон: **1701 тест / 231 сьют, все зелёные** (базлайн до раунда — 1638/225).

## Изменённые файлы
- `MiCoder/Sources/Services/ProviderAutoDetector.swift` — жёсткий дедлайн (`probeOnce` race), отменяемый `URLSessionProviderProbe` (`URLSessionTaskBox`).
- `MiCoder/Sources/Services/LocalProviderConfig.swift` — `LocalProviderKind.acp`, `apiBaseURL`, честный маппинг конфига, `isDuplicate`, `AutoDetectStatusText`.
- `MiCoder/Sources/Services/SendRouteResolver.swift` — ACP-локальные → `SendRoute.acp`.
- `MiCoder/Sources/Views/ChatPanelView.swift` — ACP-ветка потребляет маршрут `.acp` (локальные ACP).
- `MiCoder/Sources/Views/SettingsView.swift` — статусные строки через `AutoDetectStatusText`, warning п.34 больше не стирается, dedupe через `isDuplicate`.
- `MiCoder/Tests/E23E24AutoDetectConfirmationTests.swift` — +14 тестов.
- `MiCoder/Tests/E04ProjectOpenIntegrityTests.swift` — фикс флаки-окна (re-open pool перед assert).

## Версия
`Info.plist`: CFBundleShortVersionString 2.17 → **2.18**, build 19 → **20**.

## Открытые пункты (честно, не закрыто)
- ⬜ Раздел 9 п.29: пошаговый текст зондирования («Проверяем Ollama…») + кнопка отмены — сейчас спиннер «Detecting…».
- ⬜ Раздел 9 п.32: HTTPS-адреса; повторная проба с API-ключом при 401 (сейчас 401 = «ничего не обнаружено»).
- ⬜ Раздел 9 п.35: тест-файл `ProviderAutoDetectorTests.swift` (401-кейс отсутствует).
- ⬜ Раздел 9 п.39 / Раздел 2: локализация UI автоопределения на 10 языков (F4).
- Ф4 зафиксирован, но не устранён в этом раунде (осознанное решение по масштабу).
