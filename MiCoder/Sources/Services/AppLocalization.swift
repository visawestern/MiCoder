import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "English"
    case russian = "Russian"
    case spanish = "Spanish"
    case french = "French"
    case german = "German"
    case chineseSimplified = "Chinese"
    case japanese = "Japanese"
    case korean = "Korean"
    case portuguese = "Portuguese"
    case arabic = "Arabic"

    var id: String { rawValue }

    static func from(stored: String) -> AppLanguage {
        AppLanguage(rawValue: stored) ?? .english
    }

    /// Native language name shown in the picker (plan Раздел 2 Блок 4 п.34).
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .chineseSimplified: return "中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .portuguese: return "Português"
        case .arabic: return "العربية"
        }
    }

    /// Flag emoji for the custom language dropdown (plan Раздел 2 Блок 4 п.32).
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .russian: return "🇷🇺"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .chineseSimplified: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .portuguese: return "🇵🇹"
        case .arabic: return "🇸🇦"
        }
    }

    /// BCP-47 locale identifier for number/date formatting.
    var localeIdentifier: String {
        switch self {
        case .english: return "en_US"
        case .russian: return "ru_RU"
        case .spanish: return "es_ES"
        case .french: return "fr_FR"
        case .german: return "de_DE"
        case .chineseSimplified: return "zh_Hans"
        case .japanese: return "ja_JP"
        case .korean: return "ko_KR"
        case .portuguese: return "pt_PT"
        case .arabic: return "ar_SA"
        }
    }

    /// Arabic needs right-to-left layout (plan Раздел 2 Блок 2 п.15).
    var isRTL: Bool { self == .arabic }
}

enum AppLocalizationKey {
    case settingsBackToWorkspace
    case settingsGeneralTitle
    case settingsAppThemeTitle
    case settingsAppThemeDescription
    case settingsLanguageTitle
    case settingsLanguageDescription
    case settingsInterfaceZoomTitle
    case settingsInterfaceZoomDescription
    case settingsInheritTerminalTitle
    case settingsInheritTerminalDescription
    case settingsTerminalFontTitle
    case settingsTerminalFontDescription
    case settingsTerminalFontPlaceholder
    case settingsTerminalFontCurrentInherited
    case settingsTerminalFontCurrentOverride
    case settingsTabGeneral
    case settingsTabCodePreview
    case settingsTabModelSettings
    case settingsTabProviders
    case settingsTabSkills
    case settingsTabMCPServers
    case settingsTabPlugins
    case settingsTabCommands
    case settingsTabIndexing
    case settingsTabUsage
    case terminalTab
    case gitTab
    case terminalWelcome
    case terminalHelpHint
    case terminalHelpOutput
    case terminalCommandNotFound
    case gitToolsTitle
    case gitChanges
    case gitNoChanges
    case gitBranch
    case gitCommit
    case gitCommitAuto
    case gitCommitCustom
    case gitReviewPush
    case gitPublish
    case gitPublishTitle
    case gitRepoName
    case gitInitTitle
    case gitVisibility
    case gitPublic
    case gitPrivate
    case gitInitialize
    case gitPublishToGithub
    case gitBusyRetrying
    case gitInstallGHTitle
    case gitInstallGHSubtitle
    case gitInstallGHButton
    case gitSignInTitle
    case gitSignInSubtitle
    case gitSignInButton
    case gitCreateAndPush
    case gitCancel
    case gitInitSubtitle
    case gitReviewComment
    case gitReviewCommentPlaceholder
    case gitReviewSummary
    case gitCommitAndPush
    case gitOpenGitHubDocs
    case planTitle
    case noStepsYet
    case completedSteps
    case waitingSteps

    // Round 10 — rebrand + settings/storage + common UI strings that were
    // hardcoded English instead of localized.
    case appDisplayName
    case statusBarIdle
    case statusBarGenerating
    case statusBarProcessing
    case newProjectTitle
    case newProjectName
    case newProjectFolder
    case newProjectChooseFolder
    case newProjectCreate
    case newProjectCancel
    case notificationsTitle
    case notificationsEmpty
    case notificationsEmptySubtitle
    case workspacesTitle
    case noTasksYet
    case justNow

    // Settings → Storage (Round 10 — full reset block was bare English).
    case storageTabTitle
    case storageStatsTitle
    case storageDatabaseSize
    case storageSnapshotSize
    case storageMessageCount
    case storageActiveSessions
    case storageArchivedSessions
    case cleanupTitle
    case deleteChatsOlderThan
    case deleteChats7Days
    case deleteChats30Days
    case deleteChats90Days
    case deleteChats180Days
    case deleteChats1Year
    case deleteChatsConfirmTitle
    case deleteChatsConfirmMessage
    case deleteButton
    case cancelButton
    case deleteAllArchivedChats
    case compressDatabase
    case resetStorageTitle
    case resetAppCache
    case resetAppCacheConfirmTitle
    case resetButton
    case archiveNow
}

enum AppLocalization {
    static func string(_ key: AppLocalizationKey, language: AppLanguage) -> String {
        let (english, russian) = translations(for: key)
        switch language {
        case .english: return english
        case .russian: return russian
        default:
            // Curated extra-language overrides where present; otherwise fall back
            // to English (standard i18n graceful fallback, not a stub). Additional
            // language coverage is added to `extraTranslations` incrementally.
            if let override = extraTranslations(for: key)[language] {
                return override
            }
            return english
        }
    }

    /// High-visibility strings translated into the 8 additional languages
    /// (plan Раздел 2 Блок 3). Keys not present fall back to English.
    private static func extraTranslations(for key: AppLocalizationKey) -> [AppLanguage: String] {
        switch key {
        case .settingsGeneralTitle:
            return [.spanish: "General", .french: "Général", .german: "Allgemein",
                    .chineseSimplified: "通用", .japanese: "一般", .korean: "일반",
                    .portuguese: "Geral", .arabic: "عام"]
        case .settingsLanguageTitle:
            return [.spanish: "Idioma", .french: "Langue", .german: "Sprache",
                    .chineseSimplified: "语言", .japanese: "言語", .korean: "언어",
                    .portuguese: "Idioma", .arabic: "اللغة"]
        case .settingsBackToWorkspace:
            return [.spanish: "Volver al espacio", .french: "Retour à l'espace", .german: "Zurück zum Workspace",
                    .chineseSimplified: "返回工作区", .japanese: "ワークスペースに戻る", .korean: "작업 공간으로",
                    .portuguese: "Voltar ao espaço", .arabic: "العودة إلى مساحة العمل"]
        // Settings tab titles — translated for every tab (plan Раздел 13 п.8/п.10).
        case .settingsTabGeneral:
            return [.spanish: "General", .french: "Général", .german: "Allgemein",
                    .chineseSimplified: "通用", .japanese: "一般", .korean: "일반", .portuguese: "Geral", .arabic: "عام"]
        case .settingsTabCodePreview:
            return [.spanish: "Vista de código", .french: "Aperçu du code", .german: "Code-Vorschau",
                    .chineseSimplified: "代码预览", .japanese: "コードプレビュー", .korean: "코드 미리보기", .portuguese: "Prévia do código", .arabic: "معاينة الكود"]
        case .settingsTabModelSettings:
            return [.spanish: "Modelos", .french: "Modèles", .german: "Modelle",
                    .chineseSimplified: "模型", .japanese: "モデル", .korean: "모델", .portuguese: "Modelos", .arabic: "النماذج"]
        case .settingsTabProviders:
            return [.spanish: "Proveedores", .french: "Fournisseurs", .german: "Anbieter",
                    .chineseSimplified: "提供商", .japanese: "プロバイダー", .korean: "제공자", .portuguese: "Provedores", .arabic: "المزودون"]
        case .settingsTabSkills:
            return [.spanish: "Habilidades", .french: "Compétences", .german: "Skills",
                    .chineseSimplified: "技能", .japanese: "スキル", .korean: "스킬", .portuguese: "Habilidades", .arabic: "المهارات"]
        case .settingsTabMCPServers:
            return [.spanish: "Servidores MCP", .french: "Serveurs MCP", .german: "MCP-Server",
                    .chineseSimplified: "MCP 服务器", .japanese: "MCP サーバー", .korean: "MCP 서버", .portuguese: "Servidores MCP", .arabic: "خوادم MCP"]
        case .settingsTabPlugins:
            return [.spanish: "Complementos", .french: "Extensions", .german: "Plugins",
                    .chineseSimplified: "插件", .japanese: "プラグイン", .korean: "플러그인", .portuguese: "Plugins", .arabic: "الإضافات"]
        case .settingsTabCommands:
            return [.spanish: "Comandos", .french: "Commandes", .german: "Befehle",
                    .chineseSimplified: "命令", .japanese: "コマンド", .korean: "명령", .portuguese: "Comandos", .arabic: "الأوامر"]
        case .settingsTabIndexing:
            return [.spanish: "Indexación", .french: "Indexation", .german: "Indizierung",
                    .chineseSimplified: "索引", .japanese: "インデックス", .korean: "인덱싱", .portuguese: "Indexação", .arabic: "الفهرسة"]
        case .settingsTabUsage:
            return [.spanish: "Uso", .french: "Utilisation", .german: "Nutzung",
                    .chineseSimplified: "使用情况", .japanese: "使用状況", .korean: "사용량", .portuguese: "Uso", .arabic: "الاستخدام"]
        // General settings row labels (plan Раздел 13 п.8/п.10).
        case .settingsAppThemeTitle:
            return [.spanish: "Tema", .french: "Thème", .german: "Design",
                    .chineseSimplified: "主题", .japanese: "テーマ", .korean: "테마", .portuguese: "Tema", .arabic: "السمة"]
        case .settingsInterfaceZoomTitle:
            return [.spanish: "Zoom de interfaz", .french: "Zoom de l'interface", .german: "Oberflächen-Zoom",
                    .chineseSimplified: "界面缩放", .japanese: "インターフェースの拡大", .korean: "인터페이스 확대", .portuguese: "Zoom da interface", .arabic: "تكبير الواجهة"]
        case .settingsInheritTerminalTitle:
            return [.spanish: "Heredar perfil del terminal", .french: "Hériter du profil du terminal", .german: "Terminal-Profil übernehmen",
                    .chineseSimplified: "继承系统终端配置", .japanese: "ターミナルプロファイルを継承", .korean: "터미널 프로필 상속", .portuguese: "Herdar perfil do terminal", .arabic: "وراثة ملف الطرفية"]
        case .settingsTerminalFontTitle:
            return [.spanish: "Fuente del terminal", .french: "Police du terminal", .german: "Terminal-Schrift",
                    .chineseSimplified: "终端字体", .japanese: "ターミナルフォント", .korean: "터미널 글꼴", .portuguese: "Fonte do terminal", .arabic: "خط الطرفية"]
        // Git panel labels (high-visibility buttons).
        case .gitCommit:
            return [.spanish: "Confirmar", .french: "Valider", .german: "Commit",
                    .chineseSimplified: "提交", .japanese: "コミット", .korean: "커밋", .portuguese: "Confirmar", .arabic: "إيداع"]
        case .gitCancel:
            return [.spanish: "Cancelar", .french: "Annuler", .german: "Abbrechen",
                    .chineseSimplified: "取消", .japanese: "キャンセル", .korean: "취소", .portuguese: "Cancelar", .arabic: "إلغاء"]
        case .gitChanges:
            return [.spanish: "Cambios", .french: "Modifications", .german: "Änderungen",
                    .chineseSimplified: "更改", .japanese: "変更", .korean: "변경", .portuguese: "Alterações", .arabic: "التغييرات"]
        default:
            return [:]
        }
    }

    private static func translations(for key: AppLocalizationKey) -> (english: String, russian: String) {
        switch key {
        case .settingsBackToWorkspace: return ("Back to workspace", "Назад в workspace")
        case .settingsGeneralTitle: return ("General", "Общие")
        case .settingsAppThemeTitle: return ("App theme", "Тема приложения")
        case .settingsAppThemeDescription: return ("Choose which theme the application interface should use.", "Выберите тему интерфейса приложения.")
        case .settingsLanguageTitle: return ("Language", "Язык")
        case .settingsLanguageDescription: return ("Choose the display language used by the application UI.", "Выберите язык интерфейса приложения.")
        case .settingsInterfaceZoomTitle: return ("Interface zoom", "Масштаб интерфейса")
        case .settingsInterfaceZoomDescription: return ("Adjust the overall size of text and controls in the current window.", "Измените общий размер текста и элементов управления в окне.")
        case .settingsInheritTerminalTitle: return ("Inherit system terminal profile", "Наследовать профиль системного Terminal")
        case .settingsInheritTerminalDescription: return ("When launching the built-in terminal, inherit login shell environment, proxy, Kubernetes variables, and local terminal font when possible.", "При запуске встроенного терминала наследовать окружение shell, proxy, Kubernetes и шрифт Terminal.app, если возможно.")
        case .settingsTerminalFontTitle: return ("Terminal font", "Шрифт терминала")
        case .settingsTerminalFontDescription: return ("Leave blank to auto-detect system terminal settings; set a value to override the MiMo terminal font.", "Оставьте пустым для автоопределения; укажите имя шрифта для переопределения.")
        case .settingsTerminalFontPlaceholder: return ("e.g. MesloLGS NF", "например MesloLGS NF")
        case .settingsTerminalFontCurrentInherited: return ("Current: %@ (inherited)", "Сейчас: %@ (унаследован)")
        case .settingsTerminalFontCurrentOverride: return ("Current: %@", "Сейчас: %@")
        case .settingsTabGeneral: return ("General", "Общие")
        case .settingsTabCodePreview: return ("Code preview", "Превью кода")
        case .settingsTabModelSettings: return ("Model settings", "Настройки моделей")
        case .settingsTabProviders: return ("Providers", "Провайдеры")
        case .settingsTabSkills: return ("Skills", "Skills")
        case .settingsTabMCPServers: return ("MCP Servers", "MCP серверы")
        case .settingsTabPlugins: return ("Plugins", "Плагины")
        case .settingsTabCommands: return ("Commands", "Команды")
        case .settingsTabIndexing: return ("Indexing", "Индексация")
        case .settingsTabUsage: return ("Usage", "Использование")
        case .terminalTab: return ("Terminal", "Терминал")
        case .gitTab: return ("Git", "Git")
        case .terminalWelcome: return ("Welcome to MiCoder Terminal", "Добро пожаловать в терминал MiCoder")
        case .terminalHelpHint: return ("Type \"help\" for commands", "Введите \"help\" для списка команд")
        case .terminalHelpOutput: return ("Available commands: clear, help, ls, pwd", "Доступные команды: clear, help, ls, pwd")
        case .terminalCommandNotFound: return ("Command not found: %@", "Команда не найдена: %@")
        case .gitToolsTitle: return ("Git tools", "Инструменты Git")
        case .gitChanges: return ("Changes", "Изменения")
        case .gitNoChanges: return ("No changes", "Нет изменений")
        case .gitBranch: return ("Branch", "Ветка")
        case .gitCommit: return ("Commit", "Коммит")
        case .gitCommitAuto: return ("Auto-generate from changes", "Авто-создать из изменений")
        case .gitCommitCustom: return ("Write custom message", "Написать своё сообщение")
        case .gitReviewPush: return ("Review & Push", "Обзор и пуш")
        case .gitPublish: return ("Publish", "Публикация")
        case .gitPublishTitle: return ("Publish to GitHub", "Опубликовать на GitHub")
        case .gitRepoName: return ("Repository name", "Имя репозитория")
        case .gitInitTitle: return ("Initialize Git Repository", "Инициализировать Git репозиторий")
        case .gitVisibility: return ("Visibility", "Видимость")
        case .gitPublic: return ("Public", "Публичный")
        case .gitPrivate: return ("Private", "Приватный")
        case .gitInitialize: return ("Initialize", "Инициализировать")
        case .gitPublishToGithub: return ("Publish to GitHub", "Опубликовать на GitHub")
        case .gitBusyRetrying: return ("Session busy, aborting and retrying...", "Сессия занята, отмена и повтор...")
        case .gitInstallGHTitle: return ("Install GitHub CLI", "Установить GitHub CLI")
        case .gitInstallGHSubtitle: return ("GitHub CLI (gh) is required to create repositories from MiMo. Install it with Homebrew, or open the docs to install manually.", "Для создания репозиториев из MiMo нужен GitHub CLI (gh). Установите его через Homebrew или откройте документацию для ручной установки.")
        case .gitInstallGHButton: return ("Install with Homebrew", "Установить через Homebrew")
        case .gitSignInTitle: return ("Sign in to GitHub", "Войти в GitHub")
        case .gitSignInSubtitle: return ("Authorize GitHub CLI in your browser. A one-time code flow will open on github.com.", "Авторизуйте GitHub CLI в браузере. Откроется страница github.com с одноразовым кодом.")
        case .gitSignInButton: return ("Sign in with browser", "Войти через браузер")
        case .gitCreateAndPush: return ("Create & Push", "Создать и запушить")
        case .gitCancel: return ("Cancel", "Отмена")
        case .gitInitSubtitle: return ("Create a local Git repository for this workspace. You can publish it to GitHub afterwards.", "Создать локальный Git-репозиторий для этого workspace. После этого его можно опубликовать на GitHub.")
        case .gitReviewComment: return ("Your comment", "Ваш комментарий")
        case .gitReviewCommentPlaceholder: return ("What did you change? (optional)", "Что вы изменили? (необязательно)")
        case .gitReviewSummary: return ("Auto summary of changes", "Автосводка изменений")
        case .gitCommitAndPush: return ("Commit & Push", "Коммит и пуш")
        case .gitOpenGitHubDocs: return ("Open install docs", "Открыть документацию")
        case .planTitle: return ("Plan", "План")
        case .noStepsYet: return ("No steps yet", "Нет шагов")
        case .completedSteps: return ("%d completed", "%d завершено")
        case .waitingSteps: return ("%d waiting", "%d ожидает")
        // Round 10: rebrand + settings-storage block + common shell strings.
        case .appDisplayName: return ("MiCoder", "MiCoder")
        case .statusBarIdle: return ("Idle", "Ожидание")
        case .statusBarGenerating: return ("Generating...", "Генерация...")
        case .statusBarProcessing: return ("Processing...", "Обработка...")
        case .newProjectTitle: return ("New Project", "Новый проект")
        case .newProjectName: return ("Project Name", "Имя проекта")
        case .newProjectFolder: return ("Folder", "Папка")
        case .newProjectChooseFolder: return ("Choose Folder", "Выбрать папку")
        case .newProjectCreate: return ("Create Project", "Создать проект")
        case .newProjectCancel: return ("Cancel", "Отмена")
        case .notificationsTitle: return ("Notifications", "Уведомления")
        case .notificationsEmpty: return ("No notifications", "Нет уведомлений")
        case .notificationsEmptySubtitle: return ("Task completions and system alerts will appear here.", "Здесь будет история уведомлений и системных событий.")
        case .workspacesTitle: return ("Workspaces", "Проекты")
        case .noTasksYet: return ("No tasks yet", "Пока нет задач")
        case .justNow: return ("now", "только что")
        case .storageTabTitle: return ("Storage", "Хранилище")
        case .storageStatsTitle: return ("Storage", "Хранилище")
        case .storageDatabaseSize: return ("Database", "База данных")
        case .storageSnapshotSize: return ("Snapshots", "Снимки")
        case .storageMessageCount: return ("Messages", "Сообщений")
        case .storageActiveSessions: return ("Active sessions", "Активные сессии")
        case .storageArchivedSessions: return ("Archived sessions", "Архивные сессии")
        case .cleanupTitle: return ("Cleanup", "Очистка")
        case .deleteChatsOlderThan: return ("Delete chats older than:", "Удалить чаты старше:")
        case .deleteChats7Days: return ("7 days", "7 дней")
        case .deleteChats30Days: return ("30 days", "30 дней")
        case .deleteChats90Days: return ("90 days", "90 дней")
        case .deleteChats180Days: return ("180 days", "180 дней")
        case .deleteChats1Year: return ("1 year", "1 год")
        case .deleteChatsConfirmTitle: return ("Delete old chats?", "Удалить старые чаты?")
        case .deleteChatsConfirmMessage: return ("This will permanently delete all chats older than %d days, including their messages. This action cannot be undone.", "Это навсегда удалит все чаты старше %d дней со всеми сообщениями. Действие нельзя отменить.")
        case .deleteButton: return ("Delete", "Удалить")
        case .cancelButton: return ("Cancel", "Отмена")
        case .deleteAllArchivedChats: return ("Delete all archived chats", "Удалить все архивные чаты")
        case .compressDatabase: return ("Compress database (VACUUM)", "Сжать базу (VACUUM)")
        case .resetStorageTitle: return ("Reset storage", "Сброс хранилища")
        case .resetAppCache: return ("Clear app cache", "Очистить кеш приложения")
        case .resetAppCacheConfirmTitle: return ("Clear app cache?", "Очистить кеш приложения?")
        case .resetButton: return ("Reset", "Сбросить")
        case .archiveNow: return ("Archive now", "Архивировать сейчас")
        }
    }

    static func settingsTabName(_ tab: SettingsTab, language: AppLanguage) -> String {
        switch tab {
        case .general: return string(.settingsTabGeneral, language: language)
        case .codePreview: return string(.settingsTabCodePreview, language: language)
        case .modelSettings: return string(.settingsTabModelSettings, language: language)
        case .providers: return string(.settingsTabProviders, language: language)
        case .skills: return string(.settingsTabSkills, language: language)
        case .mcpServers: return string(.settingsTabMCPServers, language: language)
        case .plugins: return string(.settingsTabPlugins, language: language)
        case .commands: return string(.settingsTabCommands, language: language)
        case .indexing: return string(.settingsTabIndexing, language: language)
        case .storage:
            switch language {
            case .russian: return "Хранилище"
            case .spanish: return "Almacenamiento"
            case .french: return "Stockage"
            case .german: return "Speicher"
            case .chineseSimplified: return "存储"
            case .japanese: return "ストレージ"
            case .korean: return "저장소"
            case .portuguese: return "Armazenamento"
            case .arabic: return "التخزين"
            case .english: return "Storage"
            }
        case .usage: return string(.settingsTabUsage, language: language)
        }
    }
}
