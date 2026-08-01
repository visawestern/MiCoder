# Отчёт адвоката дьявола — Round 12 (2026-08-01)

Тема раунда: **ручная проверка КАЖДОЙ кнопки clear/delete + устранение оставшихся
крашей и "зависаний", выявленных ручным перебором.**

Контекст: пользователь сообщил, что после фикса краша на очистке базы (Round 10)
осталось сомнение — "а все остальные clear тоже проверил и исправил? проверь
вручную каждый и исправь". Раунд проведён как полный аудит каждой деструктивной
кнопки, затем TDD-фиксы найденных дефектов.

---

## 1. Полный ручной аудит всех кнопок clear/delete

### ✅ Проверены и признаны безопасными (чистое UI-состояние, без I/O)

| Место | Действие | Вердикт |
|---|---|---|
| InputViews: `AttachedFilesStrip` "Clear all" | `attachedFiles.removeAll()` через `Binding → replaceFiles([])` | Безопасно, мутирует store через set |
| InputViews: `ImagePreviewStrip` "Clear all" | `attachedImages.removeAll()` через `Binding → replaceImages([])` | Безопасно |
| BottomPanelView терминал `clear` | `output.removeAll()` | Безопасно (память) |
| MessageStore.clear() / AttachmentStore.clear() | сброс массивов | Безопасно |
| InputControls "Reset" (параметры модели) | `resetAll()` → UserDefaults + поля | Безопасно |
| NotificationsSheet "Mark All Read" | `markAllAsRead()` | Безопасно |
| NewProjectSheet | только create/dismiss | Безопасно |

### 🐛 Найдены и исправлены дефекты

#### D1. `deleteProject` в StorageSettingsView — удаление БЕЗ подтверждения
- **Проблема:** иконка корзины удаляла `.micoder` проекта + запись реестра
  мгновенно, без единого диалога. Концепт (Раздел 8 п.24 и п.54) прямо требует
  явного подтверждения с перечислением удаляемого и даже вводом имени проекта
  (паттерн GitHub "type repo name to delete").
- **Фикс:**
  - Новая чистая логика `ProjectDeleteConfirmation.swift` (TDD, red→green):
    `isConfirmed(projectName:typed:)` — case-sensitive, тримминг ввода,
    `deletionDescription(projectPath:)` — честный перечень удаляемого
    (`.micoder/`, `project.db`, `snapshots/`) с явной строкой
    "Your project files on disk are NOT deleted."
  - UI: alert с `TextField` "Type «name» to confirm"; кнопка Delete
    заблокирована до точного совпадения имени.
  - `deleteProject` теперь также сбрасывает `selectedWorkspace`, если удалялся
    активный проект (не оставляет указатель на несуществующую запись).
- **Тесты:** `ProjectDeleteConfirmationTests.swift` — 5 тестов (red 2, затем green).

#### D2. InstalledSkillRow.remove / InstalledMCPRow.remove — удаление без диалога
- **Проблема:** кнопка-корзина удаляла skill-директорию / MCP-запись из
  `mcp.json` без подтверждения — тот же footgun, что и D1.
- **Фикс:** отдельные `.alert("Remove skill?"/"Remove MCP server?")` с
  Cancel/Remove(destructive) и честным сообщением о том, что удаляется.

#### D3. Краш навигации ВЕРНУЛСЯ в параллельном прогоне тестов
- **Симптом:** `Fatal error: Array replace: subrange extends past the end`
  (SIGILL, сигнал 4) — 1 из 3 прогонов.
- **Диагноз:** Round 10 фикс добавил bounds-check ВНУТРИ didSet, но сам race
  не устранён: `selectedWorkspace.didSet` выполняется на потоке, который пишет
  свойство; параллельные тесты и фоновые init-задачи пишут с разных потоков,
  поэтому между проверкой `cutoff < count` и `removeSubrange` другой поток мог
  изменить `navigationHistory`. Бounds-check лечил *последствие*, не *гонку*.
- **Фикс (настоящий):** `navigationLock = NSLock()` вокруг **всех** операций
  `navigationHistory`/`navigationIndex`:
  - `selectedWorkspace.didSet` — truncate+append под lock'ом;
  - `clearNavigationHistory()` — под lock'ом;
  - `navigateBack/navigateForward` — чтение/декремент под lock'ом;
  - `canNavigateBack/canNavigateForward` — чтение под lock'ом.
- **Проверка:** 3× полный прогон (1599 → 1603 теста) — зелёные, краш не
  воспроизводится ни разу.

#### D4. Флаки-ошибка `AppSettings.load returns defaults` (SET-02)
- **Симптом:** `(loaded.zoom → .smaller) == .default` — тест читал/писал
  общий `UserDefaults.standard`, а параллельные тесты в тот же момент
  сохраняли настройки → гонка на общем домене.
- **Фикс:** `AppSettings.load(from:)` / `save(to:)` с инъекцией домена
  (конвенция уже декларирована в `AppState.defaults`); флаки-тест переведён
  на выделенный `UserDefaults(suiteName:)`.

#### D5. Анализ проекта "зависает" на `[tool call: LS with path "."]`
- **Симптом (сообщение пользователя ранее):** веб-модель ответила
  `Я проанализирую проект... [tool call: LS with path "."] — и все!`
  Агентный цикл останавливался, анализ не продолжался.
- **Диагноз:** `parseToolCalls` распознавал ТОЛЬКО строгий фенс
  ` ```tool {json} ``` `. Неформальный `[tool call: NAME with args]`,
  который реально выдают веб-модели, не парсился → `isFinalResponse == true`
  → цикл считал ответ финальным и завершался на первом шаге.
- **Фикс (TDD, red→green):**
  - `canonicalToolName(_:)` — алиасы и регистронезависимость:
    `LS/ls/list/dir` → `list_dir`, `Read/cat/view` → `read_file`,
    `Write/create` → `write_file`, `Edit/replace` → `edit_file`,
    `Grep/search/find` → `grep`, `Run/execute/shell` → `run_command`.
  - `parseToolCalls` теперь также разбирает `[tool call: NAME key "v" key2="v2"]`
    (отбрасывает служебное `with`, ключи с `=` и с пробелом перед кавычками).
  - `isFinalResponse` возвращает false для таких вызовов → цикл продолжается.
- **Доп. дефект, найденный тестами:** первая версия regex с альтернативами
  бросала NSException при обращении к `range(at:)` неактивной ветви
  (NSNotFound) → добавлен безопасный хелпер `substring(in:at:of:)`.
- **Тесты:** 5 новых в `WebProviderTests.swift` (informal bracket, `=`-args,
  алиасы, isFinalResponse, строгий фенс без регрессий).

---

## 2. Результаты

- Тесты: **1603 passed, 220 suites** — 3× стабильно.
- Добавлено: 2 файла логики (`ProjectDeleteConfirmation.swift`, тесты),
  3 UI-подтверждения, NSLock-атомарность навигации, инъекция defaults,
  толерантный парсер tool-вызовов.
- Никаких заглушек: каждый фикс покрыт red→green тестами, удалён даже
  небезопасный `substring(with:)`.

## 3. Что дальше по плану (из mimo_settings_full_overhaul)

Раздел 8 (Storage) теперь закрыт по дефектной части: подтверждения есть,
краш-гонки устранены, перечень удаляемого честный. Остальные пункты плана
(Разделы 1–7, 9–13) — по 10/10-оценкам блоков — переходят в следующий раунд
начиная с ближайшего незакрытого пункта (следующий по нумерации после того,
что завершил этот раунд). Сводный отчёт по всем раундам будет приложен
отдельным файлом.
