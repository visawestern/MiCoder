import Foundation
import Combine

/// Runtime localization resolver. Returns the string in the current app
/// language, falling back to English when no translation exists.
enum LocalizationRuntime {
    /// The current language. Set by AppState on language change.
    static var currentLanguage: AppLanguage = .english

    private static let russian: [String: String] = [
        "New task": "Новая задача",
        "Search": "Поиск",
        "Overview": "Обзор",
        "Workspaces": "Проекты",
        "No tasks yet": "Пока нет задач",
        "Notifications": "Уведомления",
        "No notifications": "Нет уведомлений",
        "Task completions and system alerts will appear here.": "Здесь будут уведомления о завершении задач и системных событиях.",
        "Archived projects": "Архивные проекты",
        "No archived projects": "Нет архивных проектов",
        "Open full storage panel": "Открыть полную панель хранилища",
        "Esc to close": "Esc для закрытия",
        "Settings": "Настройки",
        "Loading older messages...": "Загрузка старых сообщений...",
        "Thinking": "Думаю...",
        "Stop (⌃C)": "Стоп (⌃C)",
        "Close": "Закрыть",
        "Clear all": "Очистить все",
        "Remove": "Удалить",
        "Keep": "Оставить",
        "Open folder": "Открыть папку",
        "Show in Finder": "Показать в Finder",
        "Web providers (browser)": "Веб-провайдеры (браузер)",
        "System prompt": "Системный промпт",
        "Custom models": "Свои модели",
        "Managed browser": "Управляемый браузер",
        "Existing Chrome (cookies)": "Существующий Chrome (cookies)",
        "Add": "Добавить",
        "Templates": "Шаблоны",
        "Changes": "Изменения",
        "No changes": "Нет изменений",
        "Enter a name for the new branch. Current branch:": "Введите имя новой ветки. Текущая ветка:",
        "Title": "Заголовок",
        "Description (optional)": "Описание (необязательно)",
        "Back": "Назад",
        "New Project": "Новый проект",
        "Project Name": "Имя проекта",
        "Folder": "Папка",
        "Create Project": "Создать проект",
        "Choose folder": "Выбрать папку",
        "Projects": "Проекты",
        "Terminal": "Терминал",
        "MiCoder": "MiCoder",
        "Library": "Библиотека",
        "Code preview": "Превью кода",
        "Model settings": "Настройки моделей",
        "Providers & models": "Провайдеры и модели",
        "Add provider": "Добавить провайдер",
        "Providers": "Провайдеры",
        "Details": "Подробности",
        "Base URL": "Базовый URL",
        "API Key": "API ключ",
        "Enable function/tool calling support": "Включить поддержку вызова функций/инструментов",
        "Enable Agent Coder Protocol": "Включить Agent Coder Protocol",
        "Tools unavailable for current model": "Инструменты недоступны для текущей модели",
        "Models": "Модели",
        "Test Connection": "Проверить подключение",
        "Skills": "Навыки",
        "Installed": "Установлено",
        "MCP Servers": "MCP серверы",
        "Configured": "Настроено",
        "Plugins": "Плагины",
        "Commands": "Команды",
        "Indexing": "Индексация",
        "Codebase": "Кодовая база",
        "Storage & Database": "Хранилище и база данных",
        "Usage": "Использование",
        "Auto-archive": "Автоархивация",
        "Archive after:": "Архивировать через:",
        "Cleanup": "Очистка",
        "Delete chats older than:": "Удалить чаты старше:",
        "Storage quota exceeded": "Квота хранилища превышена",
        "No projects registered yet.": "Пока нет зарегистрированных проектов.",
        "Archived": "Архивные",
        "Orphaned (path missing)": "Осиротевшие (путь отсутствует)",
        "No usage data for the selected period.": "Нет данных об использовании за выбранный период.",
        "Local providers": "Локальные провайдеры",
        "Confirm and add": "Подтвердить и добавить",
        "No providers configured": "Нет настроенных провайдеров",
        "No parameters available": "Нет доступных параметров",
        "Model Details": "Подробности модели",
        "Configuration": "Конфигурация",
        "Remove provider": "Удалить провайдер",
        "Select": "Выбрать",
        "Parameters": "Параметры",
        "Copy info": "Копировать информацию",
        "Cannot preview image": "Невозможно просмотреть изображение",
        "Image Preview": "Превью изображения",
        "View image": "Просмотреть изображение",
        "Switch to Plan agent": "Переключить на агент Планирования",
        "Connect the local agent or add a custom provider": "Подключите локального агента или добавьте своего провайдера",
        "Custom": "Свой",
        "Select a provider first": "Сначала выберите провайдер",
        "No models for this provider": "Нет моделей для этого провайдера",
        "Remote connection": "Удалённое подключение",
        "Connect to a local agent instance on another host.": "Подключиться к локальному агенту на другом хосте.",
        "Plan mode is unavailable for the selected provider/model.": "Режим планирования недоступен для выбранного провайдера/модели.",
        "Stop generation": "Остановить генерацию",
        "Tools unavailable for the current model or provider.": "Инструменты недоступны для текущей модели или провайдера.",
        "Tool-call delay: %d ms": "Задержка вызова инструментов: %d мс",
        "Keep-alive: %ds": "Поддержание связи: %dс",
        "Uninstalled %d": "Удалено %d",
        "This deletes": "Это удалит",
        "from": "из",
        "and its registry entry. This cannot be undone.": "и его запись в реестре. Это нельзя отменить.",
        "Uninstall": "Удалить",
        "Install": "Установить",
        "Configure": "Настроить",
        "Enable": "Включить",
        "Disable": "Отключить",
        "Edit": "Редактировать",
        "Find new path…": "Найти новый путь…",
        "Delete project (requires typing its name)": "Удалить проект (требует ввода имени)",
        "Delete Old": "Удалить старые",
        "Delete Archived": "Удалить архивные",
        "Compress": "Сжать",
        "Export": "Экспорт",
        "Import": "Импорт",
        "Vacuum": "VACUUM",
        "Audit Log": "Журнал аудита",
        "Refresh": "Обновить",
        "Log in": "Войти",
        "Refresh models": "Обновить модели",
        "Refresh effort": "Обновить усилие",
        "Save": "Сохранить",
        "Cancel": "Отмена",
        "Clear": "Очистить",
        "All": "Все",
        "Has sessions": "Есть сессии",
        "Empty": "Пустые",
        "Name A–Z": "Имя А–Я",
        "Name Z–A": "Имя Я–А",
        "Recent use": "Недавние",
        "Task count": "По задачам",
        "Sort workspaces": "Сортировать проекты",
        "Filter workspaces": "Фильтровать проекты",
        "Toggle list/grid view": "Переключить вид списка/сетки",
        "All workspaces": "Все проекты",
        "Notifications (%d unread)": "Уведомления (%d непрочитано)",
        "Close (Esc)": "Закрыть (Esc)",
        "Esc": "Esc",
        "Bulk-archive projects not opened in the selected number of days (plan Раздел 8 п.25)": "Массовая архивация проектов, не открывавшихся в течение выбранного количества дней",
        "Delete record (requires typing its name)": "Удалить запись (требует ввода имени)",
        "Compress this project's database (VACUUM)": "Сжать базу данных этого проекта (VACUUM)",
        "Export this project's database + snapshots as a .zip backup": "Экспортировать базу данных + снимки этого проекта как .zip бэкап",
        "Restore this project's database + snapshots from a .zip backup": "Восстановить базу данных + снимки этого проекта из .zip бэкапа",
        "Web provider error:": "Ошибка веб-провайдера:",
        "Model note:": "Примечание о модели:",
        "Effort note:": "Примечание об усилии:",
    ]

    static func t(_ key: String) -> String {
        switch currentLanguage {
        case .russian:
            return russian[key] ?? key
        default:
            return key
        }
    }

    static func t(_ key: String, _ args: CVarArg...) -> String {
        let format = russian[key] ?? key
        switch currentLanguage {
        case .russian:
            return String(format: format, arguments: args)
        default:
            return String(format: key, arguments: args)
        }
    }
}

// Shorthand for localized strings.
enum L {
    static func t(_ key: String) -> String { LocalizationRuntime.t(key) }
    static func t(_ key: String, _ args: CVarArg...) -> String {
        LocalizationRuntime.t(key, args)
    }
}
