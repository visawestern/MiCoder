# Аудит отправки и интерактивных элементов MiCoder

Дата аудита: 2026-08-13. Объект: `visawestern/MiCoder`, ветка `main`.

## Подтверждённые проблемы по исходному коду

| ID | Область | Наблюдение | Риск | Доказательство |
|---|---|---|---|---|
| WEB-01 | Выбор модели | В меню композитора `AppState.selectModel` меняет только глобальный `selectedModel`. Для web-провайдера значение не записывается в `WebProviderConfig.selectedModel`, хотя `runWebChatTurn` передаёт в `WebChatDriver` именно конфигурацию из `WebProviderStore`. | Пользователь видит выбранную модель A, а браузер перед отправкой получает сохранённую ранее модель B. | `MiCoderApp.swift:492-506`, `ChatPanelView.swift:626-643`, `WebChatDriver.swift:195-216`. |
| WEB-02 | Effort/режим | `VariantMenu` получает варианты только из `ProviderSettingsLogic`, которая работает с server/custom provider и не знает web-provider capabilities. Для web-провайдеров effort из чата не отображается и не меняется; фактический send использует устаревший `config.effort`. | Модель/effort путаются, выбранное значение не соответствует реальному клику в веб-интерфейсе. | `InputControls.swift:290-337`, `ProviderSettingsLogic.swift:101-191`, `WebProviderConfig.swift:121-146`, `WebChatDriver.swift:218-233`. |
| WEB-03 | Element picker | В `ElementDetailSheet` вычисляется обновлённая конфигурация, но результат `WebProviderStore.upsert` игнорируется; сохраняется старый массив провайдеров. | Выбранный DOM-селектор исчезает после закрытия окна, автодетект продолжает использовать старый селектор. | `WebProvidersSection.swift:534-541`, `789-818`. |
| WEB-04 | Модель web-провайдера | После выбора web-провайдера `selectProvider` меняет `selectedModel` на первый доступный, но не синхронизирует его с `WebProviderConfig.selectedModel`. | UI и реальный browser driver расходятся уже сразу после переключения провайдера. | `MiCoderApp.swift:457-467`, `WebProviderConfig.swift:113-193`. |
| WEB-05 | Создание web-сессии | Вход через login sheet сохраняет cookies, но send-path не различает transport `playwrightMCP` и `cdpCookies`: оба идут в `WKWebViewBrowserBridge`. | Настройка transport выглядит функциональной, но выбранный режим не меняет фактический механизм отправки. | `WebProviderConfig.swift:67-74`, `ChatPanelView.swift:923-1016`, `WebProvidersSection.swift:329-334`. |
| WEB-06 | Ошибки web-инъекций | `WebChatDriver.injectModelAndEffort` сообщает ошибки как события, но `runTurn` после них продолжает отправку. | Пользователь получает ответ не от выбранной модели/effort, не получая блокирующей ошибки. | `WebChatDriver.swift:29-33`, `185-233`. |
| WEB-07 | Web readiness | `WebProviderConnectivity.models(for:)` показывает vendor defaults, если discovery не состоялся. Эти имена не гарантируют наличие в текущем UI сайта. | Пользователь может выбрать модель, которой нет в браузере; затем отправка молча продолжает с другой моделью или падает. | `WebProviderConnectivity.swift:31-37`, `WebChatDriver.swift:195-216`. |
| MIMO-01 | mimo-auto backend | Нормальная отправка через `SendRoute.mimoServe` требует доступного HTTP backend на `127.0.0.1:4096`; приложение его не запускает, а только проверяет health. | `mimo-auto` выглядит как готовый провайдер, но при остановленном backend отправка невозможна. | `MimoServeConnectionManager.swift:25-48`, `MiCoderApp.swift:294-341`, `SendRouteResolver.swift:59-60`. |
| MIMO-02 | mimo-auto response | `MimoServeClient.sendMessage` принимает только HTTP 2xx и декодирует response как message/array/true. При ином успешном JSON форматe возвращает пустой массив; UI затем ждёт SSE или оставляет пустой bubble. | Ответ может не показаться даже после успешного запроса. | `MimoServeClient.swift:194-231`, `ChatPanelView.swift:736-795`. |
| MIMO-03 | SSE endpoint | После отправки открывается SSE на `/global/event`, но response/SSE correlation зависит от серверных событий и не имеет явного timeout/error event в UI. | При отсутствии SSE пользователь видит бесконечное ожидание либо пустой ответ. | `ChatPanelView.swift:724-741`, `749-795`. |

## Карта поведения кнопок

| Элемент | Ожидаемое поведение | Текущее действие | Итог проверки |
|---|---|---|---|
| `+` | Открыть меню файлов/фото/упоминаний и сохранить вложения до отправки | Открывает `PlusMenuView` | Логика маршрута присутствует; требуется ручная macOS-проверка picker и передачи вложений. |
| Access level | Изменить разрешения и объяснить последствия | Меняет `appState.accessLevel`, синхронизирует server permission | Логика присутствует; текст и disabled Plan требуют UX-проверки. |
| Agent mode | Переключить Build/Plan/Compose | Меняет `appState.agentMode`, Plan блокируется capability gate | Логика присутствует; для web/local capability определяется слишком общо. |
| Provider | Переключить источник и каскадно выбрать валидную модель | Меняет `selectedProviderID`; web-модель синхронизируется только в UI | Ошибка WEB-04. |
| Model | Выбрать модель текущего провайдера | Меняет только `appState.selectedModel` | Ошибка WEB-01 для web. |
| Parameters | Настроить temperature/max tokens/top-p/system prompt | Сохраняет настройки по `selectedModel` | Для web-провайдера параметры не применяются browser driver. Нужно явно скрыть/объяснить либо реализовать. |
| Variant/effort | Выбрать доступный effort для текущего провайдера/модели | Показывается только для server/custom capability | Ошибка WEB-02 для web. |
| Send | Отправить либо показать причину блокировки | Вызывает `sendMessage`, затем route resolver | Для mimo-auto зависит от внешнего backend; ошибки MIMO-02/03 ухудшают обратную связь. |
| Stop | Немедленно остановить генерацию и убрать loading | Отменяет task, SSE и вызывает abort для serve | Для web не отменяет browser generation через stop button/JS; требуется исправление. |
| Login | Открыть встроенный web login и сохранить cookies | Открывает `WebProviderLoginView`, capture сохраняет cookies | Логика есть; статус зависит от ToS и cookie expiry. |
| Detect models | Прочитать реальный список моделей | Discovery через dropdown selector | Нельзя считать успехом, если selector stale; ошибка WEB-03 усугубляет это. |
| Refresh models | Повторить discovery в persistent web view | Обновляет discoveredModels | Не синхронизирует selectedModel с выбранным в чате. |
| Refresh effort | Прочитать effort/thinking levels | Записывает `discoveredEffortLevels`, выбирает первый | Не предоставляет управление из composer и всегда меняет на первый уровень. |
| Element picker | Сохранить выбранный selector и повторить discovery | UI показывает sheet, but upsert result ignored | Ошибка WEB-03. |
| Capture session | Сохранить cookies и сделать provider connected | Сохраняет cookie store и закрывает sheet | Логика есть; transport selection не влияет на send. |
| Remove | Удалить provider и исключить его из picker | Удаляет config из local state/store | Нужна confirmation и очистка cookie store; иначе stale session остаётся на диске. |

## Первичный план исправлений

Сначала нужно сделать единый объект выбора для web-провайдера: provider ID, model ID, effort и transport должны изменяться одной операцией и сразу сохраняться в `WebProviderStore`. Затем web composer должен показывать только реально обнаруженные модели и effort либо явно маркировать fallback как непроверенный. `WebChatDriver` должен считать неудачу инъекции модели/effort блокирующей ошибкой, а не продолжать отправку незаметно. После этого требуется исправить picker persistence, реализовать честную отмену web-генерации и усилить стандартный serve path таймаутом и понятными состояниями `connecting`, `sending`, `waiting for stream`, `failed`.
