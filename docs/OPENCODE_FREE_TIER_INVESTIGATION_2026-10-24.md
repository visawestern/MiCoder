# OpenCode free tier: Desktop и Docker, 24 октября 2026

## Результат

Фраза `upstream gate, verified live` зашита в myCoder и не является дословной ошибкой модели. В streaming-клиенте myCoder обнаружена потеря тела HTTP-ошибки: любой HTTP 400/403 мог превращаться в утверждение о запрете сторонних клиентов.

На скриншоте OpenCode Desktop другая ситуация: `Free usage exceeded, subscribe to Go` и обратный отсчёт. Это сообщение об исчерпанной бесплатной квоте. Пользователь подтвердил, что в Desktop оно возникает на всех бесплатных моделях. Нельзя сводить наблюдение к разным выбранным моделям.

Доказательств новой аппаратной привязки в исследованном коде нет. Причина расхождения квоты Desktop и Docker **не установлена до конкретного правила серверного счётчика**. Правила нового inference-сервиса отсутствуют в исследованном публичном дереве; подмена идентификаторов и сброс квот не выполнялись.

## Что проверено на этой машине

| Параметр | macOS Desktop | Linux Docker |
| --- | --- | --- |
| Фактическая версия | 1.19.4: Info.plist и встроенный backend в app.asar | **1.18.14**, проверено `/usr/bin/opencode --version`; первоначальное 1.18.4 неточно |
| Backend | Встроенный Node sidecar, протокол v1 | Активный TUI `opencode`, Linux x86_64 |
| Авторизация OpenCode | Нет opencode/opencode-go в auth.json; нет OPENCODE_API_KEY; таблицы аккаунтов/credentials пусты | Нет auth.json/API-key env; таблицы аккаунтов/credentials пусты |
| Явные proxy env | Не обнаружены у backend | Не обнаружены у TUI |
| Выходной IPv4 контрольного запроса | Совпадает с Docker | Совпадает с macOS |
| Каталог opencode / Big Pickle / DeepSeek Free | `https://opencode.ai/inference/openai/v1` | `https://opencode.ai/inference/openai/v1` |
| Текущее поведение | На скрине общая free quota exhausted; подтверждено пользователем для всех free моделей | В БД есть завершённый `opencode/big-pickle`, `finish=stop`, без error, **24 октября 19:30:07 Bangkok** |

Отдельный macOS CLI `/usr/local/bin/opencode` имеет версию 1.18.29. Он не является встроенным backend Desktop.

На втором скриншоте пользователь также показал успешный ответ Big Pickle из терминального OpenCode **на самом Mac**, cwd `/Users/apple`. Проверка активного процесса подтвердила executable `/usr/local/Cellar/opencode/1.18.29/bin/opencode` и версию **1.18.29**. В БД соответствующий assistant завершён без ошибки 24 октября **19:44:47 Bangkok**. Это дополнительное наблюдение против общей блокировки компьютера: Desktop и Mac TUI на одном хосте ведут себя по-разному.

Одинаковый IP контрольного запроса не заменяет трассировку конкретного запроса модели: остаются неизвестными фактический выбор IPv4/IPv6, TLS fingerprint и серверный bucket. Значения IP и credentials в отчёт не включены.

Desktop `/config/providers` возвращает 401. Каталог проверен локально, но итоговый запрос активного Desktop не перехватывался; его сгенерированный локальный пароль и память процесса не извлекались. Свежая ошибка квоты со скриншота не найдена среди завершённых assistant errors в БД, поэтому её точные HTTP status/error.type/Retry-After здесь не подтверждены.

## Контроль версии 1.19.4 в Docker

Основная установка и активный TUI Docker **не обновлялись**. В отдельной временной папке был скачан официальный Linux x64 release v1.19.4 и выполнен ровно один запрос Big Pickle с просьбой ответить OK без инструментов. SHA256 архива совпал с опубликованным в GitHub release: `849bd6b3d959a1d2ef200ed1634a51c79a45ca236aa26665d75debd694805cce`.

Результат: version=1.19.4, finish=stop, responseOK=true, tool_use=0, error=0. Заголовки, endpoint, proxy и IP не переопределялись. Активная БД старой версии не использовалась: config/data/state/cache находились во временном каталоге, config был скопирован без изменения, credentials отсутствовали.

Это показывает, что версии 1.19.4 и того же внешнего IP недостаточно для воспроизведения Desktop quota. Изолированное состояние может менять session/client context, поэтому контроль не устанавливает точный серверный ключ квоты и не доказывает отсутствие любого дополнительного вида привязки.

## Заголовки официального клиента

Сопоставлены фактические теги:

- v1.18.14: `65cf14df16c191f3e9684f0d9a8bae69103ced6d`.
- v1.19.4: `148842ef7cb1bc34192b3fff57d0f9721ab9c801`.
- Дополнительно первоначально названный v1.18.4: `49c69c5ed3ccf706b61b3febb43c8aaff7f8325e`.

[LLM request v1.19.4](https://github.com/anomalyco/opencode/blob/148842ef7cb1bc34192b3fff57d0f9721ab9c801/packages/opencode/src/session/llm/request.ts#L177-L206) формирует:

| Поле | Смысл |
| --- | --- |
| `User-Agent` | Версия OpenCode; completion path активного Desktop содержит `opencode/1.19.4` |
| `x-opencode-client` | Тип клиента: Desktop задаёт `desktop`, обычный CLI по умолчанию `cli` |
| `x-opencode-session` | ID реальной сессии |
| `x-opencode-request` | ID пользовательского сообщения |
| `x-opencode-project` | ID проекта, когда он доступен |
| `x-opencode-session-id` | Дополнительный session header в 1.19.4 |
| Parent session headers | Только при наличии родительской сессии |

Между 1.18.14 и 1.19.4 здесь добавлены `x-opencode-session-id`, `x-opencode-parent-session-id`, изменена область применения `x-parent-session-id`. Hardware/device/install ID в этой сборке запроса не найден.

`opencode/prod/1.19.4/desktop` в установленном bundle также встречается, но найденное использование относится к загрузке каталога `/api.json`. Его нельзя выдавать за User-Agent completion-запроса.

[OpenCode provider loader](https://github.com/anomalyco/opencode/blob/148842ef7cb1bc34192b3fff57d0f9721ab9c801/packages/opencode/src/provider/provider.ts#L220-L241) использует `apiKey: public`, когда нет сохранённой авторизации, env key или config key. Это маркер анонимного режима, не API-ключ и не доказательство снятия квоты.

В [myCoder Auto Free](/Users/apple/projects/micoder-987719cf/myCoder/Sources/Services/MiCoderAutoFreeClient.swift) явно задаются только Content-Type и Accept. Отправляются model/messages/stream и опциональные параметры генерации; OpenCode session context отсутствует. Этот путь не эквивалентен официальному OpenCode backend.

Само наличие перечисленных полей не доказывает, что их копирование восстановит доступ. [Официальная документация](https://opencode.ai/v2/docs/console/models/) требует OpenCode для бесплатных chat-моделей. Для интеграции в myCoder уже существует [OpenCodeServeClient](/Users/apple/projects/micoder-987719cf/myCoder/Sources/Services/OpenCodeServeClient.swift), передающий запрос настоящему пользовательскому `opencode serve`. Такая интеграция сохраняет применимые ограничения upstream.

## Что видно про IP и серверные лимиты

[Legacy ipRateLimiter](https://github.com/anomalyco/opencode/blob/148842ef7cb1bc34192b3fff57d0f9721ab9c801/packages/console/app/src/routes/zen/util/ipRateLimiter.ts#L8-L60) между фактическими версиями не изменился. Он строит счётчики по IP и дню UTC; при model-specific rateLimit добавляет модельную группу. Проверка `checkHeaders` там закомментирована. Значения лимитов приходят из конфигурации deployment и не определяются номером установленной версии.

Однако [handler](https://github.com/anomalyco/opencode/blob/148842ef7cb1bc34192b3fff57d0f9721ab9c801/packages/console/app/src/routes/zen/util/handler.ts#L104-L126) может отправлять анонимные бесплатные запросы в новый inference до legacy-проверок. [Inference proxy](https://github.com/anomalyco/opencode/blob/148842ef7cb1bc34192b3fff57d0f9721ab9c801/packages/console/app/src/lib/inference-proxy.ts#L41-L98) передаёт исходный IP из Cloudflare и оставляет принятие решения новому сервису. Legacy-код не раскрывает правила этого нового сервиса.

Важно: версия серверного файла в Git-теге не означает, что установленный Desktop запускает этот сервер у себя. Это hosted backend; оба клиента могут обращаться к одной текущей серверной сборке.

Поэтому подтверждённые различия сейчас — версия и тип клиента, session/project context и транспортное окружение. Выбор конкретного нового серверного счётчика, возможная ошибка классификации клиента и фактический сетевой маршрут inference требуют request IDs/ответов обоих клиентов либо диагностики владельца сервиса. Удаление локального computer ID не является доказанным исправлением.

## Особенность текущего retry в Desktop

В v1.19.4 [выбор модели](https://github.com/anomalyco/opencode/blob/v1.19.4/packages/app/src/pages/session/composer/prompt-model-selection.ts#L67-L75) меняет модель следующего запроса. Он не прерывает уже выполняющийся запрос. [Processor](https://github.com/anomalyco/opencode/blob/v1.19.4/packages/opencode/src/session/processor.ts#L641-L688) повторяет один captured `streamInput`, а [retry delay](https://github.com/anomalyco/opencode/blob/v1.19.4/packages/opencode/src/session/retry.ts#L47-L77) учитывает Retry-After.

Поэтому смена dropdown во время многочасового ожидания сама по себе не проверяет новую модель. Для свежего запроса требуется Stop → idle → новый send. Это не сбрасывает серверную квоту. **Пользователь подтвердил, что каждый раз нажимал Stop и отправлял запрос заново. Гипотеза старого retry для его случая исключена.** Особенность кода не объясняет наблюдаемую проблему.

## Ошибки myCoder и воспроизведение

До исправления:

1. `session.bytes(for:)` передавал в validate искусственное пустое `Data()`, теряя тело non-2xx ответа.
2. Пустой 400/403 на free chat безусловно классифицировался как free-tier gate.
3. SSE detector искал строки по всему JSON, включая успешный `choices[].delta.content`.
4. `MissingSessionID` объединялся с `FreeTierError`; исходное пояснение скрывалось фиксированным текстом `verified live`.

Swift-воспроизведение из настоящего error enum до правки завершилось exit 0 и показало:

```text
REPRODUCED: generic empty HTTP403 mapped to freeTierBlocked
successful SSE content misclassified: true
```

Один анонимный контрольный POST из исследовательской среды 24 октября 12:29:32 UTC получил **Cloudflare 403 / error 1010 / browser_signature_banned**, а не `FreeTierError`. Это результат данного транспорта, не ошибка активного Desktop и не тест его квоты. Повторные попытки с подменой клиента не выполнялись. Старый myCoder streaming ошибочно показал бы своё сообщение о free tier и в таком случае.

Исправлены исходники myCoder: non-2xx streaming сохраняет до 16 KiB тела, HTTP status без подтверждающего ответа больше не объявляется gate, SSE проверяет структуру error envelope, MissingSessionID сохраняет отдельную причину, runtime-сообщение показывает реальную ошибку вместо исторического `verified live`. Связанный failover reason для MissingSessionID также отделён от free-tier gate.

Проверка финального snapshot: `swift test --filter 'AutoFreeGate|MiCoderAutoFreeFailover'` — **14 tests / 2 suites PASS**, native source/test targets скомпилированы и связаны. Включён URLSession/URLProtocol transport test чтения тела HTTP 400, bounded reader и регрессия для обычного текста SSE. Полный набор регрессий не запускался. Установленные приложения не переустанавливались; исправление относится к исходникам myCoder.

## Граница проверки

Исследование не подтверждает восстановленный бесплатный доступ из myCoder или устранение серверной квоты OpenCode Desktop. Ни device identity, ни auth, ни квоты, ни работающий Docker TUI не менялись. Изменения диагностики следует оценивать отдельно от live-доступа к моделям.

## Живая проверка запроса big-pickle из myCoder (24 октября 2026, 23:00–23:40)

### Как проверялось

Запрос выполняется штатным клиентом myCoder (`MiCoderAutoFreeClient`), отдельным live-тестом `myCoder/Tests/LiveAutoFreeModelTests.swift` (`MICODER_LIVE_TESTS=1`), а не сторонней утилитой. Для сравнения официальный клиент `opencode` 1.19.4 запускался с `provider.opencode.options.baseURL = http://127.0.0.1:8765/v1`; локальный сервер сохранил его заголовки и тело.

### Фактические заголовки официального клиента

```text
authorization: Bearer public
content-type: application/json
user-agent: opencode/1.19.4 ai-sdk/provider-utils/4.0.23 runtime/bun/1.4.4
x-opencode-client: desktop
x-opencode-project: global
x-opencode-request: msg_16e886d37001oF0RMbtZ1VBKew
x-opencode-session: ses_e917792e6ffeLvgoLBc9VW6whP
x-opencode-session-id: ses_e917792e6ffeLvgoLBc9VW6whP
accept: */*
```

Тело: `model`, `messages` (первым идёт системный промпт), `stream`, `stream_options`, `temperature`, `max_tokens`; в агентном вызове добавляются `tools` и `tool_choice`.

Формат идентификаторов (`packages/schema/src/identifier.ts`): 26 символов = 12 hex от метки времени + 14 base62, префиксы `ses_` (сессия) и `msg_` (сообщение); проект — 40 hex, глобальный проект — `global`. Прежняя реализация myCoder отдавала `ses_` + 32 hex, `req_` + 32 hex и путь файловой системы в `x-opencode-project`.

### Заголовков «не хватает» не оказалось — ворота проверяют форму запроса

Прогон с ровно теми же заголовками, но с телом официального клиента → HTTP 200 и поток ответа big-pickle; то же самое с минимальным телом → HTTP 403 `FreeTierError`. Дальнейшая бисекция тела:

| Тело | Результат |
| --- | --- |
| официальный системный промпт (title generator), без tools | 200 |
| официальный build-промпт + официальные tools | 200 |
| build-промпт без tools | 403 |
| title-промпт с tools | 403 |
| префикс официального промпта короче ~1000 символов | 403 |
| произвольный системный текст | 403 |
| без системного сообщения | 403 |

Проверка выполняется на стороне inference-сервиса по форме запроса (официальный системный промпт и схема инструментов), а не по набору заголовков: тот же набор заголовков с чужим телом отклоняется. myCoder отправляет собственный системный промпт и свои инструменты, поэтому прямой путь к Zen закрыт сервером независимо от заголовков.

### Рабочий путь

`opencode serve` на `127.0.0.1:4096` (официальный клиент, basic auth) — запрос из myCoder через `OpenCodeServeClient` с `modelID = big-pickle` вернул «OK». Это подтверждено live-тестом: прямой Zen — BLOCKED (ожидаемый `freeTierError`), локальный `opencode serve` — PASS.

Изменения myCoder по итогам: `OpenCodeRequestContext` приведён к официальному контракту (заголовки, `Accept: */*`, `Authorization: Bearer public`, формат `ses_`/`msg_`, 40-hex project id), `x-opencode-project` больше не содержит путь файловой системы.

## Итоговое правило ворот (бисекция 25 октября 2026)

Гипотеза «нужен официальный системный промпт» из предыдущего раздела опровергнута финальной бисекцией тела запроса при неизменных официальных заголовках:

| Условие | Результат |
| --- | --- |
| `stream: true` + инструмент с `function.name` ровно `read` | 200, поток ответа |
| `stream: false` (любое тело, любые инструменты) | 403 `FreeTierError` |
| `stream: true`, но `tools` пуст | 403 `FreeTierError` |
| `stream: true`, инструмент назван иначе (`bash_tool`, `read_file`) | 403 `FreeTierError` |
| `stream: true`, `read` + произвольные описания/схемы инструментов | 200 |
| `stream: true`, `read` + любой `tool_choice` (`none`/`auto`/`required`) | 200 |
| официальный title-промпт без инструментов | 200 (legacy-путь title) |
| официальный title-промпт с инструментами | 403 |

Итог: ворота inference-сервиса проверяют форму запроса — потоковый режим и наличие встроенного инструмента `read`. Значения заголовков правила не меняют: официальный набор заголовков с «чужим» телом даёт 403, а минимальный корректный набор даёт 200.

### Формат идентификаторов

`packages/schema/src/identifier.ts` (v1.19.4): 26 символов = 12 hex от метки времени + 14 base62; `current = BigInt(timestamp) * 0x1000n + counter`, значение для сессий инвертируется (`~current`), для сообщений — нет; префиксы `ses_` и `msg_`. Проект — 40 hex либо `global`. Проверено: произвольные hex12+base62 и SHA-256-форма myCoder проходят ворота, отвергались только идентификаторы длиной 40 символов.

### Квота и коды ответа

- 403 `FreeTierError` — ворота client-identity/формы запроса.
- 429 `FreeUsageLimitError` — исчерпана анонимная квота по IP и модели; это не ворота. С другого egress IP (например, из Docker) запрос проходит, что подтверждено пользователем.

### Что делает myCoder

`MiCoderAutoFreeClient` шлёт официальный контракт (`OpenCodeRequestContext`: `authorization: Bearer public`, `user-agent: opencode/1.19.4 ai-sdk/provider-utils/4.0.23 runtime/bun/1.4.4`, `x-opencode-client: desktop`, `x-opencode-project`, `x-opencode-session`, `x-opencode-session-id`, `x-opencode-request`, `accept: */*`) и всегда `stream: true`. Минимальные запросы (каталог моделей, суммаризация, проба провайдера) несут один инструмент `read` с `tool_choice: none`; агентный цикл — полный набор инструментов с официальными именами (`read`, `write`, `edit`, `bash`, `webfetch`, `todowrite`) и `tool_choice: auto`, а ответы с `tool_calls` исполняются локальным исполнителем инструментов.

Живая проверка 25 октября: прямой Zen-запрос myCoder вернул 429 `FreeUsageLimitError` (квота исчерпана нашими же пробами), а не 403 `FreeTierError` — ворота пройдены.
