# MiCoder — независимый acceptance-аудит требований из полного диалога

**Дата:** 14 августа 2026 года. **Объект проверки:** текущий checkout `visawestern/MiCoder`, commit `f0d8f25`. **Метод:** независимая трассировка control/trigger → handler → state → persistence → runtime consumer → visible result, с отдельными оценками качества реализации и соответствия задаче.

> **Итоговый вердикт:** прежние заявления о том, что web-модели, effort, browser sending и chat isolation «сделаны», не подтверждаются полным end-to-end приёмочным аудитом. По нормализованному чеклисту из 32 крупных требований нет ни одного полностью подтверждённого target-runtime PASS; 14 требований имеют FAIL по текущему поведению, 18 — PARTIAL. Среднее качество реализации — **2,25/5**, среднее соответствие поставленной задаче — **1,31/5**.

## 1. Границы и честность проверки

В Linux sandbox невозможно собрать полный macOS target: `swift test` останавливается на отсутствии модулей `SwiftUI` и `AppKit` в `MiCoder/Sources/App/MiCoderApp.swift`. Это не следует считать «тесты прошли». Foundation-only web harness, составленный из чистых сервисов и соответствующих тестов, завершился с **55/55**, но он проверяет только pure/Foundation orchestration, Codable, fake-browser discovery и session persistence. Он не доказывает работу SwiftUI, WebKit DOM, cookie store, внешних Kimi/Qwen/ChatGPT аккаунтов, реального model dropdown, удалённого chat UUID или ответа внешней модели.

Существующие activity-checklists прямо указывают, что WebKit, Finder, Keychain и внешние аккаунты требуют live macOS-сеанса и должны быть `PARTIAL`, а не `PASS` [1]. Тем не менее cumulative report и canonical CSV содержат множество `PASS` с примечанием «live verification pending». В этом аудите такие строки переоценены независимо.

| Evidence level | Что доказано | Что не доказано |
|---|---|---|
| Source trace | Синтаксическая и структурная цепочка существует | Что SwiftUI/WebKit control реально нажимается и даёт ожидаемый результат |
| Foundation harness | Pure logic, fake browser, Codable, bounded pool/journal, 55 tests | macOS framework, реальный DOM, cookies, provider response |
| Linux full package | **Не выполнен:** compile stop на SwiftUI/AppKit | Все UI и target-runtime требования |
| macOS build/runtime | В текущем sandbox отсутствует | `build-app.sh`, Xcode compile, WebKit, внешние аккаунты |
| Screenshot evidence | Подтверждает видимые текущие UX-дефекты | Поведение после будущих исправлений |

## 2. Главные подтверждённые дефекты

### 2.1 Web discovery не является строгим model detector

Цепочка выглядит как `findModelsBuiltIn()` → `WebModelDiscovery.discoverAllModels()` → `discover()` → `WKWebViewBrowserBridge.readModelItems()` → `WebModelListParser.parse()` → сохранение `discoveredModels` → UI. Разрыв находится в двух местах. `readModelItems()` принимает короткий `innerText` любого найденного option/container и использует fallback `[role="option"]`, `[class*="option"]`, `li`; затем `WebModelListParser.normalize()` пропускает любой короткий токен с буквами. Поэтому `Model` и `Model Comparison` проходят как будто это модели. В тестах эта слабость уже закреплена: `Быстрый` прямо ожидается как Kimi model, хотя это effort label [2].

Скриншот показывает расхождение: верхняя строка сообщает `16 моделей найдено`, среди первых результатов видны `Model`, `Model Comparison`, `Qwen3.8-Max` и `+13`, а каталог ниже содержит только три модели: `Qwen3.7-Max`, `Qwen3.7-Plus`, `Qwen3.8-Max`. Это не единичная ошибка отображения; это несовпадение между acquisition, validation, persistence и UI.

### 2.2 Expand models обходится неполно и не проверяется по результату

`discoverAllModels()` кликает по широкому селектору `button, a, [role='button'], [role='menuitem'], li, div` и затем читает один общий item selector. В production path не существует строгого подтверждения, что был нажат именно submenu control, что меню действительно расширилось, что число items увеличилось, и что все nested branches обработаны. Тест проверяет только одну простую fake-ветку из пяти элементов [2]. Пользовательский Qwen screenshot подтверждает, что реальный путь всё ещё теряет модели вроде Qwen Coder.

### 2.3 Effort не профилируется в полном login/detection chain

В `persistCookies()` после захвата cookies запускается только `refreshModels()` [3]. Combined `discoverAllModels()` + `discoverModelCapabilities()` существует в login sheet, но card-level refresh и post-login persistence не используют гарантированно полный model/effort/profile workflow. На карточках виден `Effort: not detected`, а per-model capability list не представлен пользователю. Таким образом, наличие функции `discoverEffort()` не означает выполнение требования «сразу определить effort у каждой модели».

### 2.4 Обнаруженный список моделей скрыт и ограничен

`WebProviderCard` показывает count-only toggle и рендерит `config.discoveredModels.prefix(8)` с `+ N more` [3]. Это прямо противоречит требованиям «показывать список определённых моделей» и «видеть все модели». В settings `ModelSettingsView` действительно есть full-width group header с `Show/Hide`, но это другая модельная поверхность; она не исправляет count-only provider card и не гарантирует полноту live web catalog.

### 2.5 «Выбрать» всё ещё существует как лишнее действие

`compactModelCard` не имеет row-level selection action. Модель выбирается только через vertical-dots menu, где всё ещё присутствует `Label(L.t(AppLocalizationKey.locSelect), ...)` [4]. Пользователь просил кликом по строке выбирать модель и оставить отдельным действием только параметры. Текущий код делает обратное: клик по строке ничего не выбирает, а menu предлагает лишний промежуточный `Выбрать`.

### 2.6 Remote web chat UUID отсутствует в production chain

Локальная изоляция `WKWebView` действительно использует `projectID + chatID + providerID` [5]. Однако это не равно изоляции удалённых web conversations. `WebChatDriver.startNewSession()` и `getCurrentChatID()` только определены, но production caller отсутствует. `ChatSession` не имеет `remoteChatID`. `runWebChatTurn()` при открытии страницы делает только best-effort `clickByText` по локальному title [6]. `webSessionStarted` keyed only by provider ID [7].

Фактическая цепочка поэтому такова: локальный chat ID → local WKWebView key → navigate/reuse current remote page → optional title text click → type/send. В ней нет шага `create/select remote chat by UUID`, нет сохранения remote UUID и нет проверки, что выбран именно нужный provider conversation. Пользовательский риск «контекстная каша» подтверждён исходным кодом.

### 2.7 Auto Free имеет policy и state, но не подтверждённый внешний результат

MiCoder Auto Free имеет отдельный OpenCode Zen client, free allow-list, rate-limit policy и fallback loop [8]. NotificationCenter → AppState → ChatPanel banner chain существует, но notification semantic type остаётся `.warning`, хотя пользователь требовал заметный красный failure alert [9]. Более того, live external send в текущей среде не проверен. Поэтому policy tests не превращаются в доказательство рабочего provider.

## 3. Полный независимый checklist и оценки

Полная таблица находится в `ACCEPTANCE_MATRIX.csv`. В ней 32 нормализованных требования из полного диалога, статус реализации, оценка реализации 0–5, оценка task-fit 0–5, target-runtime status и source-chain evidence.

| Сводка | Значение |
|---|---:|
| Нормализованных крупных требований | 32 |
| `FAIL` по текущей независимой проверке | 14 |
| `PARTIAL` | 18 |
| Подтверждённых target-runtime PASS | 0 |
| Среднее качество реализации | 2,25/5 |
| Среднее соответствие задаче | 1,31/5 |
| Требования с task-fit 0/5 | AUD-02, AUD-15, AUD-16, AUD-17, AUD-18, AUD-25, AUD-26, AUD-28, AUD-30, AUD-32 |

### Критический acceptance checklist

| Требование пользователя | Реализация | Следование задаче | Результат цепочки |
|---|---:|---:|---|
| Отфильтровать `Model`, `Model Comparison` и прочий UI noise | **0/5** | **0/5** | Parser принимает короткий любой token с буквами; screenshot подтверждает false positives |
| Найти все модели через Expand models, включая Qwen Coder | **1/5** | **0/5** | Fake test проходит, реальный screenshot показывает 3 вместо полного списка |
| Сразу найти effort у каждой модели | **1/5** | **0/5** | На provider cards `Effort: not detected`; post-login callback запускает models-only refresh |
| Показать полный список определённых моделей | **2/5** | **1/5** | Provider card count-only и `prefix(8)`; часть списка исчезает |
| Аккордеон вместо маленького chevron | **2/5** | **1/5** | Accordion есть в другой settings surface, но live detected list остаётся compact toggle |
| Выбор модели обычным кликом по строке | **2/5** | **1/5** | Row не выбирает; выбор спрятан в menu |
| Убрать `Выбрать` | **2/5** | **1/5** | `locSelect` всё ещё в menu |
| Сохранить и использовать remote chat UUID | **0/5** | **0/5** | Нет поля, production caller и persistence |
| Новый project/chat/subagent → новый remote chat | **0/5** | **0/5** | Reuse current remote page; только local WKWebView identity |
| Правильно выбрать существующий remote chat | **1/5** | **0/5** | Best-effort title click, без UUID и post-selection verification |
| Web send через hidden browser | **2/5** | **1/5** | Orchestration присутствует, target WebKit response не проверен и пользователь сообщает failure |
| Named independent logins | **4/5** | **3/5** | Pure persistence passed; live two-account cookie switch unverified |
| MiCoder Auto Free failover | **3/5** | **2/5** | State/policy/banner chain exists; external send and severity not fully accepted |
| Sidebar/header fixes | **4/5** | **3/5** | Source structure supports them; no current macOS visual run |

## 4. Что считать реально сделанным

Надёжно подтверждены только чистые участки: 55/55 Foundation tests, Codable migration, named-session file persistence/list/restore, local browser instance key equality, bounded journal behavior, pure route/policy tests, and source parse of individual Swift files. Это **не** равно рабочему продукту на macOS.

Частично реализованы named sessions, local WKWebView pool, Auto Free failover policy, provider-local actions, sidebar responsive source, and explicit DOM/AI detection split. They require target-runtime acceptance and currently do not satisfy the user's web requirements because the core catalog and remote-chat chain are broken.

## 5. Приоритет исправлений перед новым PASS

**P0 — discovery contract.** Introduce a strict vendor-aware `WebModelCandidate` validator. Reject UI headings, action labels, effort labels, descriptions, counts, and generic words such as `model`, `model comparison`, `all models`, `more`, `settings`, `upgrade`, and localized equivalents. Read only visible leaf option nodes and return candidate metadata: `active`, `selectable`, `unsupported`, `sourcePath`, and `rawLabel`. Never persist an unvalidated label.

**P0 — Qwen/Kimi nested traversal.** Use a DOM probe that returns structured visible menu nodes with stable identity, parent/child relationship, exact text, `role`, classes, disabled state, and bounds. Click the exact expand control, wait for item count/DOM fingerprint increase, re-read the complete menu, repeat until no new branch exists, and record a discovery trace. The acceptance test must include multi-level branches and Qwen Coder.

**P0 — per-model capability transaction.** After each validated model selection, probe effort and parameter controls, record `active/unsupported/not-detected/error` separately, restore the originally selected model, and persist one atomic provider catalog snapshot. Login refresh, manual refresh, and retry refresh must call the same combined path.

**P0 — remote chat identity.** Add a persisted mapping keyed by `projectID + localChatID + providerID + activeSessionID`, containing `remoteChatID`, remote URL, last verified title, and last-used timestamp. On first turn call `startNewSession()`, extract/validate UUID with `getCurrentChatID()`, persist it, and use it on later turns. On local chat/project/subagent switch, open the mapped remote chat or create a new one; never rely on title substring matching alone. Include remote ID in browser journal and final route message.

**P1 — direct model UX.** Replace provider card count toggle and `prefix(8)` with a full-width accordion containing all validated candidates. Clicking a row selects it immediately and visibly; vertical-dots menu keeps only `Parameters`, `Copy info`, and provider-specific actions. Separate active, unsupported, and removable manual entries. Do not call an action `Выбрать` when the row itself is the selector.

**P1 — acceptance build.** Run `./build-app.sh` and full `swift test` on a real macOS machine, then execute a scripted manual matrix for Kimi, Qwen, and ChatGPT with screenshots/logs for discovery count, each model's effort state, remote UUID mapping, session switching, and one forced injection failure. Only then promote rows from PARTIAL to PASS.

## References

[1]: ./activity-checklists/00-index.md "Activity checklist index and live verification limits"
[2]: ../.acceptance/ACCEPTANCE_MATRIX.csv "Independent acceptance matrix and current test evidence"
[3]: ../MiCoder/Sources/Views/Components/WebProvidersSection.swift "Provider card and login/detection chain"
[4]: ../MiCoder/Sources/Views/Settings/ModelSettingsView.swift "Model row interaction and redundant Select action"
[5]: ../MiCoder/Sources/App/MiCoderApp.swift "WKWebView project/chat/provider pool"
[6]: ../MiCoder/Sources/Views/ChatPanelView.swift "Web send chain"
[7]: ../MiCoder/Sources/App/MiCoderApp.swift "Provider-global web session seed state"
[8]: ../MiCoder/Sources/Services/MiCoderAutoFreeProvider.swift "Auto Free runtime failover"
[9]: ../MiCoder/Sources/Services/NotificationService.swift "Auto Free notification severity"


## 6. Round 46 adversarial recheck and correction

The P0/P1 defects above were used as the implementation contract rather than silently reclassified. The live bridge now returns structured candidates, strict vendor grammar rejects UI noise, and recursive discovery requires exact expansion controls plus a changing DOM fingerprint. The added adversarial fake traverses two expansion levels and includes a Qwen Coder branch; Foundation tests pass.

The catalog now separates `active`, `inactive`, `unsupported` and `notDetected` states, with an explicit `isSelectable` invariant. AI-assisted labels are strict-validator candidates only and remain unselectable until built-in DOM discovery confirms them. The provider card and settings surface use full-width accordion/row actions, and the parameter panel displays live profile keys, labels and numeric defaults separately from user overrides. Unsupported models no longer inherit a global effort list.

Remote routing now uses a persisted mapping keyed by provider, active named session, project and local chat. New mappings require verified New Chat URL/ID change; existing mappings verify host and remote ID after navigation and fail closed on mismatch. The hidden browser instance key includes activeSessionID. Typed injection failures abort before typing; ChatPanel refreshes the same page once and retries once in the same remote mapping, so recovery cannot duplicate a prompt or mix contexts. Auto Free rate-limit notifications now use error severity and its stream path rejects selected models absent from the live free catalog.

| Round-46 evidence | Result |
|---|---|
| Foundation web harness | **68/68 passed** |
| Nested Qwen-style expansion and noise rejection | **Passed** |
| Unselectable candidate filtering | **Passed** |
| Named-session browser pool identity | **Passed** |
| Remote mapping/journal persistence | **Passed** |
| Failed injection blocks duplicate typing/send | **Passed** |
| Adversarial source contract checks | **11/11 passed** |
| Changed Swift parse and diff hygiene | **Passed** |
| macOS/WebKit live runtime | **Still unverified in Linux** |

The acceptance matrix now has **32 rows: 31 PARTIAL and 1 environment FAIL**. Code-level implementation and task-fit averages are **4.38/5**. These are not target-runtime scores: no row is promoted to 5/5 or PASS until the required Mac build and live Kimi/Qwen/WebKit checklist is executed. The original findings remain retained as historical evidence; this section records their Round-46 correction rather than deleting the audit trail.


## 7. Round 47 correction — stale persisted labels and direct accordion selection

The first checklist item had one remaining gap: strict validation protected new detection, but older provider JSON could still contain `Model` or `Model Comparison`. `WebProviderStore.load()` now sanitizes decoded configurations before any provider card, settings list or composer consumes them. Invalid labels are removed, duplicates are normalized, effort levels are rebuilt from valid profiles and an invalid selected model is cleared or replaced by the first valid selectable model.

The detected-model accordion in each provider card now supports direct selection of active validated rows. The selected row is highlighted and updates the active `web:<providerID>` plus model in `AppState`; inactive and AI-unverified rows cannot be selected and expose removal instead. The settings surface retains the full-width accordion and direct row click, while its vertical-dots menu has only Parameters, Copy info and provider-specific controls.

Round-47 evidence: the legacy `Model`/`Model Comparison` migration test passes, the Foundation harness now passes **69/69**, all changed Swift files parse, and the 11 adversarial source checks remain green. Live macOS/WebKit discovery and visual hit-target verification still require the user's Mac, so the item is code-complete but not promoted to target-runtime PASS until that check is executed.
