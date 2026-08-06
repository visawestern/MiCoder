# Чеклист: Боковая панель (SidebarView.swift)

Источник: `MiCoder/Sources/Views/SidebarView.swift` (959 LOC). Основные действия:

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 1 | Новая задача | Верх боковой панели, `SidebarActionRow` (:12) | Кнопка «New task» / ⌘N | Создаётся новая сессия, открывается пустой чат; есть `.help("New task")` (:666) и дублирующая кнопка (:774) | ✅ |
| 2 | Новый проект | Верх боковой панели (:15) | Кнопка «New Project» / ⌘⇧P | Открывается `NewProjectSheet` (имя + выбор папки) | ✅ |
| 3 | Поиск задач | Поле «Search tasks…» | Ввод текста | Фильтрация списка сессий по названию | ✅ |
| 4 | Секция Workspaces | `WorkspacesSectionHeader` | Клик по заголовку | Разворачивание/сворачивание списка воркспейсов | ✅ |
| 5 | Поиск воркспейсов | Поле «Search workspaces» | Показ при `showWorkspaceSearchField` | Фильтрация воркспейсов; при пустом результате «No matching workspaces» | ✅ |
| 6 | Переключение list/grid | Кнопка «Toggle list/grid view» | Клик | Переключение отображения сессий между списком и сеткой | ✅ |
| 7 | Сортировка воркспейсов | «Sort workspaces» (chevron.down) | Клик | Смена порядка/пресета сортировки | ✅ |
| 8 | Фильтр «All workspaces» / «Archived projects» | Меню фильтра | Клик | Переключение фильтра; подпись `Filter: \(workspaceFilterPreset.rawValue)` | ✅ |
| 9 | Открытие сессии | Элемент сессии в списке | Клик | Выбор сессии → она показывается в чате; «Open Session» в контекстном меню | ✅ |
| 10 | Восстановление архивированного | «Restore» в контекстном меню | Клик | Сессия возвращается из архива; при пустом архиве «No archived projects» | ✅ |
| 11 | Просмотр изменений | «View Changes» | Клик | Открывается панель Git/изменений по сессии | ✅ |
| 12 | Открыть в Finder | «Open in Finder» | Клик | Открывается папка проекта/воркспейса | ✅ |
| 13 | Полная панель хранения | «Open full storage panel» | Клик | Открывается вкладка Storage настроек | ✅ |
| 14 | Уведомления | Секция «Notifications (N unread)» (bell, badge счётчика) | Клик | Открытие списка; «Mark All Read» сбрасывает счётчик; при пустом — «No notifications» + пояснение «Task completions and system alerts will appear here.»; «Open Settings» открывает настройки | ✅ |
| 15 | Настройки | Кнопка «Settings» (gearshape) | Клик | Открывается окно настроек | ✅ |
| 16 | Пустой список воркспейсов | «No workspaces» | — | Пустое состояние с приглашением создать воркспейс | ✅ |
| 17 | Пустой список задач | «No tasks yet» | — | Пустое состояние списка сессий | ✅ |
| 18 | Относительное время | Подписи «Nm ago» / «Nh ago» / «Nd ago» | — | Форматирование времени последней активности сессии | ✅ |
| 19 | Счётчик сессий воркспейса | Бейдж `\(workspaceSessions.count)` | — | Количество сессий в воркспейсе | ✅ |

## Найденные проблемы / замечания

- ⚠️ «Search»-строка воркспейсов появляется только при `showWorkspaceSearchField` — триггер показа
  сам по себе скрыт; без явного входа в поиск пользователь может не найти поле. UX-замечание.
- ⚠️ «Restore» доступно только из контекстного меню архивированной сессии; прямой кнопки
  восстановления в списке нет.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
