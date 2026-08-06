# Чеклист: Топбар, заголовок задачи, статус-бар, новый проект

Источники: `Views/TopBarView.swift`, `Views/TaskHeaderView.swift`, `Views/StatusBarView.swift`,
`Views/NewProjectSheet.swift`.

## TopBarView

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 1 | Показ проекта | Левый блок | — | Имя воркспейса/проекта + иконка «folder» | ✅ |
| 2 | Индикатор ветки | Рядом с именем проекта | — | Текущая ветка Git (иконка «flag»/«command») | ✅ |
| 3 | Бейдж цели | «Goal» (иконка «command») | — | Бейдж показывается, когда у сессии задана цель (`/goal`, plan Раздел 5 Блок 1 п.9) | ✅ |
| 4 | Переключение терминала | Кнопка «Terminal» | Клик | Показ/скрытие нижней панели терминала | ✅ |
| 5 | Бренд | Надпись «MiCoder» | — | Брендированное имя приложения (Round 23 — пользовательские строки «MiMo» устранены) | ✅ |

## TaskHeaderView

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 6 | Показ заголовка | Между TopBar и чатом | Наличие выбранной сессии | Виден только если `TaskHeaderVisibility.shouldShow(selectedSession:)` (при `selectedSession != nil`) | ✅ |
| 7 | Бейджи воркспейса/ветки | `folder.fill` / «main» | — | Имя воркспейса и текущая ветка | ✅ |
| 8 | Копирование чата | Кнопка «Copy entire chat» (doc.on.doc) | Клик | Весь чат в буфер; тултип «Copy» → «Copied» (checkmark) | ✅ |
| 9 | Открыть терминал | Кнопка «Terminal» | Клик | Показ нижней панели терминала | ✅ |

## StatusBarView

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 10 | Состояние подключения | Точка в статус-баре | — | «Connected» / «Disconnected» | ✅ |
| 11 | Адрес сервера | `\(serverHost):\(serverPort)` | — | Отображение адреса локального сервера | ✅ |
| 12 | Модель | Чип модели | — | Имя текущей модели | ✅ |
| 13 | Индикаторы | cpu / network / спиннер | — | Загрузка/генерация/сетевая активность | ✅ |

## NewProjectSheet

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 14 | Имя проекта | Поле «Project Name» (placeholder «My Project») | Ввод | Валидация и использование имени | ✅ |
| 15 | Выбор папки | Поле «Folder» + «Choose folder» / «Select» / «Choose project folder» (folder.badge.plus) | Клик | Нативный выбор папки проекта (placeholder «/Path/to/project») | ✅ |
| 16 | Создание | Кнопка «Create Project» | Клик | Создание проекта из имени + папки, закрытие листа | ✅ |
| 17 | Отмена | Кнопка «Cancel» / Esc | Клик/Esc | Закрытие листа без изменений | ✅ |

## Найденные проблемы / замечания

- ⚠️ TaskHeaderView появляется/скрывается по `TaskHeaderVisibility.shouldShow` — при пустом
  состоянии (нет выбранной сессии) часть действий (Copy entire chat, Terminal) недоступна без
  объяснения.
- ⚠️ Бейдж «Goal» показывает факт наличия цели, но сама цель (текст `/goal`) видна только в чате.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
