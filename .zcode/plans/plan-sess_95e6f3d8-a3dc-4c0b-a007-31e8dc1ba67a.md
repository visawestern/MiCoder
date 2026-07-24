## Архитектура: Локальная SQLite БД + Optional Mimo Serve + Система Отката

### Ключевая идея
Текущий проект полностью зависит от Mimo Serve (health, sessions, models — всё через HTTP). Нужно сделать Mimo опциональным, а все данные хранить локально в SQLite.

**Библиотека**: GRDB.swift (native Swift SQLite, Codable, async, FTS5, migrations built-in)

### SQLite Schema (15 таблиц)

1. **projects** — id, name, path, branch, is_active, sort_order, created_at, updated_at, last_accessed
2. **sessions** — id, project_id (FK), title, directory, branch, server_id, model_id, provider_id, variant, agent_mode, token_usage, cost, created_at, updated_at, is_finished
3. **messages** — id, session_id (FK), role (user|assistant|system), content, reasoning, is_streaming, is_finished, agent_name, tokens_added/removed, error_message, server_id, created_at, updated_at, parent_id (FK self)
4. **message_parts** — id, message_id (FK), part_type (text|reasoning|toolCall|stepStart|stepFinish|image), part_order, part_data (JSON), tool_name, tool_args, tool_result, tool_call_id, image_mime, image_data
5. **tool_invocations** — id, session_id, message_id, tool_name (Read|Write|Edit|Bash|Grep|WebFetch|Task|AskUserQuestion|sleep|wait), provider, arguments (JSON), result (JSON), error, status (pending|running|completed|failed|cancelled), duration_ms, token_cost, created_at, completed_at
6. **actions** — id, session_id, tool_call_id, action_type (file_write|file_edit|file_delete|bash_run|git_commit|git_push), target_path, description, state_before (JSON), state_after (JSON), is_reversible, is_reverted, reverted_at, depends_on (FK self)
7. **file_snapshots** — id, action_id (FK), file_path, content_before, content_after, mime_type, file_size_before/after, checksum_before/after (SHA256)
8. **providers** — id, name, provider_type (openAI|anthropic|google|ollama|mimo), base_url, api_key (Keychain encrypted), is_enabled, supports_tools, acp_enabled, models_cache (JSON)
9. **models** — id, provider_id (FK), name, capabilities (JSON: {reasoning,toolcall,plan}), variants (JSON), context_limit, cost_input/output
10. **project_preferences** — project_id (FK), provider_id, model_id, variant, agent_mode, access_level
11. **settings** — key, value (KV store вместо UserDefaults)
12-15. Индексы на все FK и часто используемые поля

### Проверочный чеклист на 120 пунктов

**Database Foundation (15):**
1. GRDB.swift через SPM
2. DatabaseManager синглтон
3. Миграции (v1→v2...)
4. Путь БД ~/.mimocode/mimo.db
5. projects table
6. sessions table
7. messages table
8. message_parts table
9. tool_invocations table
10. actions table
11. file_snapshots table
12. providers table
13. models table
14. project_preferences table
15. Индексы

**Projects/Workspaces (12):**
16. Загрузка projects из SQLite на старте
17. Сохранение project при добавлении
18. Редактирование project (name/path/branch)
19. Архивирование (is_active=0)
20. Каскадное удаление
21. Сортировка по last_accessed
22. Поиск по name
23. Grid/List view персистентность
24. Авто-создание при Open folder
25. Branch per project
26. last_accessed update при выборе
27. Дедупликация по path

**Sessions (10):**
28. Создание в SQLite (не только на сервере)
29. Привязка к project_id
30. Сохранение agent_mode/model_id
31. updated_at на каждое сообщение
32. Фильтр по project
33. Поиск по title
34. Лимит 12 в sidebar
35. Пагинация
36. Каскадное удаление
37. Длительность сессии

**Messages (15):**
38. Сохранение user сообщений
39. Сохранение assistant сообщений
40. Сохранение system сообщений
41. Сохранение text parts
42. Сохранение reasoning parts
43. Сохранение toolCall parts
44. Сохранение stepStart/Finish parts
45. Сохранение image parts
46. Восстановление из БД при загрузке
47. parent_id для редактирования
48. Инкрементальное обновление
49. SSE streaming + сохранение
50. server_id для sync
51. Full-text search (FTS5)
52. Дедупликация по id

**Tool Invocations (12):**
53. Read — файл, путь, содержимое
54. Write — файл, содержимое, размер
55. Edit/Patch — файл, diff
56. Grep/Rg — query, results
57. Bash/Shell — команда, output, exit code
58. WebFetch — URL, response
59. Task — подзадача, результат
60. AskUserQuestion — вопрос, ответ
61. Sleep/Wait — длительность
62. duration_ms каждого вызова
63. Полные JSON аргументы
64. Полный JSON результат + ошибки

**Actions & Rollback (15):**
65. Action на каждый Write (file_write)
66. Action на каждый Edit (file_edit)
67. Action на каждый Bash (bash_run)
68. Action на каждый git commit (git_commit)
69. FileSnapshot при записи файла
70. content_before (оригинал)
71. content_after (новая версия)
72. SHA256 checksum
73. Откат file_write: восстановить оригинал
74. Откат file_edit: reverse patch
75. Откат git_commit: git revert
76. Каскадный откат зависимостей
77. UI: список действий
78. UI: подсветка откаченных
79. UI: предупреждение о необратимых

**Optional Mimo (10):**
80. Mimo = один из типов провайдера
81. Провайдеры в SQLite (не UserDefaults)
82. API ключи в Keychain
83. Proxy per provider
84. Health check опционален при старте
85. Models из кэша БД offline
86. Обновление моделей online
87. Provider selector без Mimo
88. Auto-connect только mimo-тип
89. Graceful degradation

**Settings (8):**
90. Перенос AppSettings из UserDefaults
91. Theme per project
92. Provider/Model preference per project
93. Agent mode per project
94. Access level per project
95. Zoom/language
96. Terminal font
97. HTTP proxy

**Migration (8):**
98. CustomProviders → providers table
99. AppSettings → settings table
100. selectedModel → project_preferences
101. Обратная совместимость
102. Импорт sessions из Mimo при первой синхр.
103. Импорт CLI history в SQLite
104. Версионирование схемы
105. Backup/restore БД

**Bash/Sleep/Wait (5):**
106. async/await + timeout (30s)
107. stdin pipe для интерактива
108. Sleep: Task.sleep(nanoseconds:)
109. Wait: ожидание условия (файл/процесс/порт)
110. Логирование bash в tool_invocations

**TerminalView (5):**
111. Async execute (не блокирует UI)
112. 30s timeout
113. История команд ↑/↓
114. Автодополнение
115. Сохранение вывода

**History & Rollback UI (5):**
116. Панель "История действий"
117. Фильтр по типу
118. Фильтр по времени/сессии
119. "Откатить до этого момента"
120. Визуальный diff

### Оценка текущего состояния

| Статус | Количество |
|--------|-----------|
| ✅ Done | 8 (основные модели данных, работа с Mimo) |
| ⚠️ Partial | 12 (сообщения загружаются, но не сохраняются локально) |
| ❌ Missing | 85 (SQLite, rollback, optional Mimo) |
| 📋 Planned | 15 (в этой архитектуре) |

### План реализации по фазам

**Phase 1** — GRDB.swift + DatabaseManager + schema (п.1-15, 90-97)
**Phase 2** — Optional Mimo + ProviderRegistry (п.80-89) 
**Phase 3** — Project/Session/Message persistence (п.16-52)
**Phase 4** — Tool tracking + Action logging (п.53-79)
**Phase 5** — Bash/Sleep/Wait + Terminal rewrite (п.106-115)
**Phase 6** — Rollback UI + History Panel (п.116-120)
**Phase 7** — Migration + Polish (п.98-105)

### Ключевые новые файлы

| Файл | Назначение |
|------|-----------|
| Services/DatabaseManager.swift | GRDB init + migrations |
| Services/ProjectRepository.swift | CRUD projects |
| Services/SessionRepository.swift | CRUD sessions+messages |
| Services/ToolTracker.swift | Логирование tool invocations |
| Services/ActionManager.swift | Rollback система |
| Services/FileSnapshotter.swift | Снапшоты файлов |
| Services/ProviderRegistry.swift | Optional Mimo + провайдеры |
| Services/KeychainHelper.swift | Шифрование API ключей |
| Views/Components/HistoryPanelView.swift | UI для отката |
| Views/Components/ActionTimelineView.swift | Визуализация действий |

### Изменения в существующих файлах

- **MiMoMacOSApp.swift** — AppState: SQLite вместо in-memory, Mimo опционален
- **ChatSession.swift** — Codable для SQLite + project_id
- **Workspace.swift** — переименовать в Project, Codable
- **Message.swift** — Codable для SQLite
- **Settings.swift** — миграция в settings table
- **MimoServeClient.swift** — опциональный провайдер
- **GitRepository.swift** — async/await + timeout
- **BottomPanelView.swift** — Terminal: async + timeout + sleep
- **SidebarView.swift** — загрузка из SQLite
- **ChatPanelView.swift** — сохранение сообщений
- **ToolCallPresentationLogic.swift** — sleep/wait распознавание