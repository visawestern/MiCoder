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

    var isRTL: Bool { self == .arabic }
}

enum AppLocalizationKey: String {
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
    case settingsCodePreviewTitle
    case settingsLightCodeThemeTitle
    case settingsLightCodeThemeDescription
    case settingsDarkCodeThemeTitle
    case settingsDarkCodeThemeDescription
    case settingsShowLineNumbersTitle
    case settingsShowLineNumbersDescription
    case settingsWrapLongLinesTitle
    case settingsWrapLongLinesDescription
    case settingsCodeFontSizeTitle
    case settingsCodeFontSizeDescription
    case settingsModelSettingsTitle
    case settingsModelSettingsDescription
    case settingsSkillsTitle
    case settingsSkillsDescription
    case settingsSearchSkillsPlaceholder
    case settingsNoSkillsInstalled
    case settingsNoSkillsInstalledSubtitle
    case settingsMCPServersTitle
    case settingsMCPServersDescription
    case settingsSearchMCPServersPlaceholder
    case settingsNoMCPServersConfigured
    case settingsNoMCPServersConfiguredSubtitle
    case settingsPluginsTitle
    case settingsPluginsDescription
    case settingsSearchPluginsPlaceholder
    case settingsNoPluginsInstalled
    case settingsNoPluginsInstalledSubtitle
    case settingsEnabled
    case settingsDisabled
    case settingsCommandsTitle
    case settingsCommandsDescription
    case settingsSearchCommandsPlaceholder
    case settingsNoUserCommands
    case settingsNoUserCommandsSubtitle
    case settingsIndexingTitle
    case settingsIndexingCodebaseTitle
    case settingsIndexNewFoldersTitle
    case settingsIndexNewFoldersDescription
    case settingsIndexRepositoriesTitle
    case settingsIndexRepositoriesDescription
    case settingsStorageTitle
    case settingsUsageTitle
    case settingsUsageSubtitle
    case settingsUsageTimeRange
    case settingsUsageTotalTokens
    case settingsUsageTotalCost
    case settingsUsageMessages
    case settingsUsageActiveDays
    case settingsUsageDatabaseSize
    case settingsUsageFavoriteModel
    case settingsUsageFavoriteModelSubtitle
    case settingsUsageByModel
    case settingsUsageNoData
    case settingsLocalProvidersTitle
    case settingsLocalProvidersDescription
    case settingsLocalProvidersAddressPlaceholder
    case settingsLocalProvidersAutoDetect
    case settingsLocalProvidersDetecting
    case settingsLocalProvidersAdded
    case settingsLocalProvidersAdd
    case settingsLocalProvidersEnabled
    case settingsLocalProvidersDisabled
    case settingsProvidersTitle
    case settingsProvidersDescription
    case settingsProvidersStatsProviders
    case settingsProvidersStatsModels
    case settingsProvidersSearchPlaceholder
    case settingsProvidersAdd
    case settingsProvidersNoProviders
    case settingsProvidersModelsCount
    case settingsProvidersToolsEnabled
    case settingsProvidersACPEnabled
    case settingsProvidersRemove
    case settingsConfirm
    case settingsCancel
    case settingsRemove
    case settingsDelete
    case settingsArchive
    case settingsRestore
    case settingsFindNewPath
    case settingsExportBackup
    case settingsImportBackup
    case settingsCompress
    case settingsArchiveNow
    case settingsDeleteOlderThan
    case settingsTypeNameToConfirm
    case settingsDeleteProjectDescription
    case settingsStorageQuotaExceeded
    case settingsStorageQuotaDescription
    case settingsStorageQuotaArchiveInactive
    case settingsNoProjectsRegistered
    case settingsActive
    case settingsArchived
    case settingsOrphaned
    case settingsAutoArchiveDescription
    case settingsArchiveAfter
    case settingsCleanupTitle
    case settingsCleanupDeleteChatsOlderThan
    case settingsDeleteButton
    case settingsDeleteAllArchivedChats
    case settingsCompressDatabase
    case settingsResetStorageTitle
    case settingsResetAppCache
    case settingsClearAppCache
    case settingsArchiveInactive
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
        guard let entry = translations[key.rawValue] else { return key.rawValue }
        switch language {
        case .english: return entry["en"] ?? key.rawValue
        case .russian: return entry["ru"] ?? entry["en"] ?? key.rawValue
        case .spanish: return entry["es"] ?? entry["en"] ?? key.rawValue
        case .french: return entry["fr"] ?? entry["en"] ?? key.rawValue
        case .german: return entry["de"] ?? entry["en"] ?? key.rawValue
        case .chineseSimplified: return entry["zh"] ?? entry["en"] ?? key.rawValue
        case .japanese: return entry["ja"] ?? entry["en"] ?? key.rawValue
        case .korean: return entry["ko"] ?? entry["en"] ?? key.rawValue
        case .portuguese: return entry["pt"] ?? entry["en"] ?? key.rawValue
        case .arabic: return entry["ar"] ?? entry["en"] ?? key.rawValue
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

    private static let translations: [String: [String: String]] = [
        "settingsBackToWorkspace": ["en": "Back to workspace", "ru": "Назад в workspace", "es": "Volver al área de trabajo", "fr": "Retour à l'espace de travail", "de": "Zurück zum Arbeitsbereich", "zh": "返回工作区", "ja": "ワークスペースに戻る", "ko": "작업 공간으로 돌아가기", "pt": "Voltar à área de trabalho", "ar": "العودة إلى مساحة العمل"],
        "settingsGeneralTitle": ["en": "General", "ru": "Общие", "es": "General", "fr": "Général", "de": "Allgemein", "zh": "通用", "ja": "一般", "ko": "일반", "pt": "Geral", "ar": "عام"],
        "settingsAppThemeTitle": ["en": "App theme", "ru": "Тема приложения", "es": "Tema de la aplicación", "fr": "Thème de l'application", "de": "App-Design", "zh": "应用主题", "ja": "アプリのテーマ", "ko": "앱 테마", "pt": "Tema da aplicação", "ar": "سمة التطبيق"],
        "settingsAppThemeDescription": ["en": "Choose which theme the application interface should use.", "ru": "Выберите тему интерфейса приложения.", "es": "Elija qué tema debe usar la interfaz de la aplicación.", "fr": "Choisissez le thème à utiliser pour l'interface de l'application.", "de": "Wählen Sie, welches Design die Anwendungsoberfläche verwenden soll.", "zh": "选择应用程序界面使用的主题。", "ja": "アプリケーションインターフェースで使用するテーマを選択してください。", "ko": "애플리케이션 인터페이스에서 사용할 테마를 선택하세요.", "pt": "Escolha o tema que a interface da aplicação deve utilizar.", "ar": "اختر السمة التي يجب أن تستخدمها واجهة التطبيق."],
        "settingsLanguageTitle": ["en": "Language", "ru": "Язык", "es": "Idioma", "fr": "Langue", "de": "Sprache", "zh": "语言", "ja": "言語", "ko": "언어", "pt": "Idioma", "ar": "اللغة"],
        "settingsLanguageDescription": ["en": "Choose the display language used by the application UI.", "ru": "Выберите язык интерфейса приложения.", "es": "Elija el idioma de visualización usado por la interfaz.", "fr": "Choisissez la langue d'affichage utilisée par l'interface.", "de": "Wählen Sie die Anzeigesprache der Anwendungsoberfläche.", "zh": "选择应用程序界面使用的显示语言。", "ja": "アプリケーションUIで使用する表示言語を選択してください。", "ko": "애플리케이션 UI에서 사용할 표시 언어를 선택하세요.", "pt": "Escolha o idioma de visualização utilizado pela interface da aplicação.", "ar": "اختر لغة العرض المستخدمة في واجهة المستخدم."],
        "settingsInterfaceZoomTitle": ["en": "Interface zoom", "ru": "Масштаб интерфейса", "es": "Zoom de la interfaz", "fr": "Zoom de l'interface", "de": "Oberfläche-Zoom", "zh": "界面缩放", "ja": "インターフェースのズーム", "ko": "인터페이스 확대/축소", "pt": "Zoom da interface", "ar": "تكبير الواجهة"],
        "settingsInterfaceZoomDescription": ["en": "Adjust the overall size of text and controls in the current window.", "ru": "Измените общий размер текста и элементов управления в окне.", "es": "Ajuste el tamaño general del texto y los controles.", "fr": "Ajustez la taille globale du texte et des contrôles.", "de": "Passen Sie die Gesamtgröße von Text und Steuerelementen im aktuellen Fenster an.", "zh": "调整当前窗口中文字和控件的整体大小。", "ja": "現在のウィンドウでテキストとコントロールの全体的なサイズを調整します。", "ko": "현재 창에서 텍스트와 컨트롤의 전체 크기를 조정합니다.", "pt": "Ajuste o tamanho geral do texto e dos controlos na janela atual.", "ar": "اضبط الحجم العام للنص وعناصر التحكم في النافذة الحالية."],
        "settingsInheritTerminalTitle": ["en": "Inherit system terminal profile", "ru": "Наследовать профиль системного Terminal", "es": "Heredar perfil del terminal del sistema", "fr": "Hériter du profil du terminal système", "de": "System-Terminalprofil übernehmen", "zh": "继承系统终端配置文件", "ja": "システムターミナルプロファイルを継承", "ko": "시스템 터미널 프로필 상속", "pt": "Herdar perfil do terminal do sistema", "ar": "وراثة ملف تعريف طرفية النظام"],
        "settingsInheritTerminalDescription": ["en": "When launching the built-in terminal, inherit login shell environment, proxy, Kubernetes variables, and local terminal font when possible.", "ru": "При запуске встроенного терминала наследовать окружение shell, proxy, Kubernetes и шрифт Terminal.app, если возможно.", "es": "Al iniciar el terminal integrado, herede el entorno del shell, proxy, variables de Kubernetes y fuente del terminal local cuando sea posible.", "fr": "Lors du lancement du terminal intégré, héritez de l'environnement de connexion, du proxy, des variables Kubernetes et de la police du terminal local lorsque cela est possible.", "de": "Beim Starten des eingebetteten Terminals nach Möglichkeit Login-Shell-Umgebung, Proxy, Kubernetes-Variablen und lokale Terminal-Schriftart übernehmen.", "zh": "启动内置终端时，尽可能继承登录 shell 环境、代理、Kubernetes 变量和本地终端字体。", "ja": "内蔵ターミナルを起動する際、可能であればログインシェル環境、プロキシ、Kubernetes変数、ローカルターミナルフォントを継承します。", "ko": "내장 터미널을 실행할 때, 가능한 경우 로그인 셸 환경, 프록시, Kubernetes 변수 및 로컬 터미널 글꼴을 상속합니다.", "pt": "Ao iniciar o terminal integrado, herdar o ambiente de shell de início de sessão, proxy, variáveis Kubernetes e fonte do terminal local quando possível.", "ar": "عند تشغيل الطرفية المدمجة، قم بوراثة بيئة shell الدخول، والوكيل، ومتغيرات Kubernetes، وخط الطرفية المحلي عند الإمكان."],
        "settingsTerminalFontTitle": ["en": "Terminal font", "ru": "Шрифт терминала", "es": "Fuente del terminal", "fr": "Police du terminal", "de": "Terminal-Schriftart", "zh": "终端字体", "ja": "ターミナルフォント", "ko": "터미널 글꼴", "pt": "Fonte do terminal", "ar": "خط الطرفية"],
        "settingsTerminalFontDescription": ["en": "Leave blank to auto-detect system terminal settings; set a value to override the MiMo terminal font.", "ru": "Оставьте пустым для автоопределения; укажите имя шрифта для переопределения.", "es": "Deje en blanco para detectar automáticamente la configuración; establezca un valor para sobrescribir la fuente.", "fr": "Laissez vide pour détecter automatiquement les paramètres ; définissez une valeur pour remplacer la police MiMo.", "de": "Leer lassen zur automatischen Erkennung; setzen Sie einen Wert, um die MiMo-Terminal-Schriftart zu überschreiben.", "zh": "留空以自动检测系统终端设置；设置一个值以覆盖 MiMo 终端字体。", "ja": "空白にするとシステムターミナル設定を自動検出します。MiMoターミナルフォントを上書きする値を設定します。", "ko": "시스템 터미널 설정을 자동 감지하려면 비워두세요. MiMo 터미널 글꼴을 재정의하려면 값을 설정하세요.", "pt": "Deixe em branco para detetar automaticamente as definições do terminal do sistema; defina um valor para substituir a fonte do terminal MiMo.", "ar": "اتركه فارغًا للكشف التلقائي عن إعدادات طرفية النظام؛ حدد قيمة لتجاوز خط طرفية MiMo."],
        "settingsTerminalFontPlaceholder": ["en": "e.g. MesloLGS NF", "ru": "например MesloLGS NF", "es": "p. ej., MesloLGS NF", "fr": "par ex. MesloLGS NF", "de": "z. B. MesloLGS NF", "zh": "例如 MesloLGS NF", "ja": "例: MesloLGS NF", "ko": "예: MesloLGS NF", "pt": "ex.: MesloLGS NF", "ar": "مثال: MesloLGS NF"],
        "settingsTerminalFontCurrentInherited": ["en": "Current: %@ (inherited)", "ru": "Сейчас: %@ (унаследован)", "es": "Actual: %@ (heredado)", "fr": "Actuel : %@ (hérité)", "de": "Aktuell: %@ (übernommen)", "zh": "当前：%@（已继承）", "ja": "現在: %@（継承済み）", "ko": "현재: %@ (상속됨)", "pt": "Atual: %@ (herdado)", "ar": "الحالي: %@ (موروث)"],
        "settingsTerminalFontCurrentOverride": ["en": "Current: %@", "ru": "Сейчас: %@", "es": "Actual: %@", "fr": "Actuel : %@", "de": "Aktuell: %@", "zh": "当前：%@", "ja": "現在: %@", "ko": "현재: %@", "pt": "Atual: %@", "ar": "الحالي: %@"],
        "settingsTabGeneral": ["en": "General", "ru": "Общие", "es": "General", "fr": "Général", "de": "Allgemein", "zh": "通用", "ja": "一般", "ko": "일반", "pt": "Geral", "ar": "عام"],
        "settingsTabCodePreview": ["en": "Code preview", "ru": "Превью кода", "es": "Vista previa del código", "fr": "Aperçu du code", "de": "Code-Vorschau", "zh": "代码预览", "ja": "コードプレビュー", "ko": "코드 미리보기", "pt": "Pré-visualização de código", "ar": "معاينة الكود"],
        "settingsTabModelSettings": ["en": "Model settings", "ru": "Настройки моделей", "es": "Configuración del modelo", "fr": "Paramètres du modèle", "de": "Modelleinstellungen", "zh": "模型设置", "ja": "モデル設定", "ko": "모델 설정", "pt": "Definições do modelo", "ar": "إعدادات النموذج"],
        "settingsTabProviders": ["en": "Providers", "ru": "Провайдеры", "es": "Proveedores", "fr": "Fournisseurs", "de": "Anbieter", "zh": "提供商", "ja": "プロバイダー", "ko": "공급자", "pt": "Fornecedores", "ar": "المقدّمون"],
        "settingsTabSkills": ["en": "Skills", "ru": "Навыки", "es": "Habilidades", "fr": "Compétences", "de": "Fähigkeiten", "zh": "技能", "ja": "スキル", "ko": "스킬", "pt": "Competências", "ar": "المهارات"],
        "settingsTabMCPServers": ["en": "MCP Servers", "ru": "MCP серверы", "es": "Servidores MCP", "fr": "Serveurs MCP", "de": "MCP-Server", "zh": "MCP 服务器", "ja": "MCP サーバー", "ko": "MCP 서버", "pt": "Servidores MCP", "ar": "خوادم MCP"],
        "settingsTabPlugins": ["en": "Plugins", "ru": "Плагины", "es": "Complementos", "fr": "Plugins", "de": "Plugins", "zh": "插件", "ja": "プラグイン", "ko": "플러그인", "pt": "Plugins", "ar": "الإضافات"],
        "settingsTabCommands": ["en": "Commands", "ru": "Команды", "es": "Comandos", "fr": "Commandes", "de": "Befehle", "zh": "命令", "ja": "コマンド", "ko": "명령", "pt": "Comandos", "ar": "الأوامر"],
        "settingsTabIndexing": ["en": "Indexing", "ru": "Индексация", "es": "Indexación", "fr": "Indexation", "de": "Indizierung", "zh": "索引", "ja": "インデックス", "ko": "인덱싱", "pt": "Indexação", "ar": "الفهرسة"],
        "settingsTabUsage": ["en": "Usage", "ru": "Использование", "es": "Uso", "fr": "Utilisation", "de": "Nutzung", "zh": "使用情况", "ja": "使用状況", "ko": "사용량", "pt": "Utilização", "ar": "الاستخدام"],
        "settingsCodePreviewTitle": ["en": "CodePreview Title", "ru": ""],
        "settingsLightCodeThemeTitle": ["en": "LightCodeTheme Title", "ru": ""],
        "settingsLightCodeThemeDescription": ["en": "LightCodeTheme Description", "ru": ""],
        "settingsDarkCodeThemeTitle": ["en": "DarkCodeTheme Title", "ru": ""],
        "settingsDarkCodeThemeDescription": ["en": "DarkCodeTheme Description", "ru": ""],
        "settingsShowLineNumbersTitle": ["en": "ShowLineNumbers Title", "ru": ""],
        "settingsShowLineNumbersDescription": ["en": "ShowLineNumbers Description", "ru": ""],
        "settingsWrapLongLinesTitle": ["en": "WrapLongLines Title", "ru": ""],
        "settingsWrapLongLinesDescription": ["en": "WrapLongLines Description", "ru": ""],
        "settingsCodeFontSizeTitle": ["en": "CodeFontSize Title", "ru": ""],
        "settingsCodeFontSizeDescription": ["en": "CodeFontSize Description", "ru": ""],
        "settingsModelSettingsTitle": ["en": "ModelSettings Title", "ru": ""],
        "settingsModelSettingsDescription": ["en": "ModelSettings Description", "ru": ""],
        "settingsSkillsTitle": ["en": "Skills Title", "ru": "", "es": "Habilidades", "fr": "Compétences"],
        "settingsSkillsDescription": ["en": "Skills Description", "ru": "", "es": "Descripción de habilidades", "fr": "Description des compétences"],
        "settingsSearchSkillsPlaceholder": ["en": "SearchSkills", "ru": ""],
        "settingsNoSkillsInstalled": ["en": "NoSkillsInstalled", "ru": ""],
        "settingsNoSkillsInstalledSubtitle": ["en": "NoSkillsInstalled Subtitle", "ru": ""],
        "settingsMCPServersTitle": ["en": "MCPServers Title", "ru": ""],
        "settingsMCPServersDescription": ["en": "MCPServers Description", "ru": ""],
        "settingsSearchMCPServersPlaceholder": ["en": "SearchMCPServers", "ru": ""],
        "settingsNoMCPServersConfigured": ["en": "NoMCPServersConfigured", "ru": ""],
        "settingsNoMCPServersConfiguredSubtitle": ["en": "NoMCPServersConfigured Subtitle", "ru": ""],
        "settingsPluginsTitle": ["en": "Plugins Title", "ru": "", "es": "Complementos", "fr": "Plugins"],
        "settingsPluginsDescription": ["en": "Plugins Description", "ru": "", "es": "Descripción de complementos", "fr": "Description des plugins"],
        "settingsSearchPluginsPlaceholder": ["en": "SearchPlugins", "ru": ""],
        "settingsNoPluginsInstalled": ["en": "NoPluginsInstalled", "ru": ""],
        "settingsNoPluginsInstalledSubtitle": ["en": "NoPluginsInstalled Subtitle", "ru": ""],
        "settingsEnabled": ["en": "Enabled", "ru": "", "es": "Habilitado", "fr": "Activé"],
        "settingsDisabled": ["en": "Disabled", "ru": "", "es": "Deshabilitado", "fr": "Désactivé"],
        "settingsCommandsTitle": ["en": "Commands Title", "ru": "", "es": "Comandos", "fr": "Commandes"],
        "settingsCommandsDescription": ["en": "Commands Description", "ru": "", "es": "Descripción de comandos", "fr": "Description des commandes"],
        "settingsSearchCommandsPlaceholder": ["en": "SearchCommands", "ru": ""],
        "settingsNoUserCommands": ["en": "NoUserCommands", "ru": ""],
        "settingsNoUserCommandsSubtitle": ["en": "NoUserCommands Subtitle", "ru": ""],
        "settingsIndexingTitle": ["en": "Indexing Title", "ru": "", "es": "Indexación", "fr": "Indexation"],
        "settingsIndexingCodebaseTitle": ["en": "IndexingCodebase Title", "ru": ""],
        "settingsIndexNewFoldersTitle": ["en": "IndexNewFolders Title", "ru": ""],
        "settingsIndexNewFoldersDescription": ["en": "IndexNewFolders Description", "ru": ""],
        "settingsIndexRepositoriesTitle": ["en": "IndexRepositories Title", "ru": ""],
        "settingsIndexRepositoriesDescription": ["en": "IndexRepositories Description", "ru": ""],
        "settingsStorageTitle": ["en": "Storage  Title", "ru": ""],
        "settingsUsageTitle": ["en": "Usage Title", "ru": "", "es": "Uso", "fr": "Utilisation"],
        "settingsUsageSubtitle": ["en": "Usage Subtitle", "ru": "", "es": "Subtítulo de uso", "fr": "Résumé de l'utilisation"],
        "settingsUsageTimeRange": ["en": "UsageTimeRange", "ru": ""],
        "settingsUsageTotalTokens": ["en": "UsageTotalTokens", "ru": ""],
        "settingsUsageTotalCost": ["en": "UsageTotalCost", "ru": ""],
        "settingsUsageMessages": ["en": "UsageMessages", "ru": ""],
        "settingsUsageActiveDays": ["en": "UsageActiveDays", "ru": ""],
        "settingsUsageDatabaseSize": ["en": "UsageDatabaseSize", "ru": ""],
        "settingsUsageFavoriteModel": ["en": "UsageFavoriteModel", "ru": ""],
        "settingsUsageFavoriteModelSubtitle": ["en": "UsageFavoriteModel Subtitle", "ru": ""],
        "settingsUsageByModel": ["en": "UsageByModel", "ru": ""],
        "settingsUsageNoData": ["en": "UsageNoData", "ru": ""],
        "settingsLocalProvidersTitle": ["en": "LocalProviders Title", "ru": ""],
        "settingsLocalProvidersDescription": ["en": "LocalProviders Description", "ru": ""],
        "settingsLocalProvidersAddressPlaceholder": ["en": "LocalProvidersAddress", "ru": ""],
        "settingsLocalProvidersAutoDetect": ["en": "LocalProvidersAutoDetect", "ru": ""],
        "settingsLocalProvidersDetecting": ["en": "LocalProvidersDetecting", "ru": ""],
        "settingsLocalProvidersAdded": ["en": "LocalProvidersAdded", "ru": ""],
        "settingsLocalProvidersAdd": ["en": "LocalProvidersAdd", "ru": ""],
        "settingsLocalProvidersEnabled": ["en": "LocalProvidersEnabled", "ru": ""],
        "settingsLocalProvidersDisabled": ["en": "LocalProvidersDisabled", "ru": ""],
        "settingsProvidersTitle": ["en": "Providers Title", "ru": "", "es": "Proveedores", "fr": "Fournisseurs"],
        "settingsProvidersDescription": ["en": "Providers Description", "ru": "", "es": "Descripción de proveedores", "fr": "Description des fournisseurs"],
        "settingsProvidersStatsProviders": ["en": "ProvidersStatsProviders", "ru": ""],
        "settingsProvidersStatsModels": ["en": "ProvidersStatsModels", "ru": ""],
        "settingsProvidersSearchPlaceholder": ["en": "ProvidersSearch", "ru": ""],
        "settingsProvidersAdd": ["en": "ProvidersAdd", "ru": ""],
        "settingsProvidersNoProviders": ["en": "ProvidersNoProviders", "ru": ""],
        "settingsProvidersModelsCount": ["en": "ProvidersModelsCount", "ru": ""],
        "settingsProvidersToolsEnabled": ["en": "ProvidersToolsEnabled", "ru": ""],
        "settingsProvidersACPEnabled": ["en": "ProvidersACPEnabled", "ru": ""],
        "settingsProvidersRemove": ["en": "ProvidersRemove", "ru": ""],
        "settingsConfirm": ["en": "Confirm", "ru": "", "es": "Confirmar", "fr": "Confirmer"],
        "settingsCancel": ["en": "Cancel", "ru": "", "es": "Cancelar", "fr": "Annuler", "de": "Abbrechen", "zh": "取消", "ja": "キャンセル", "ko": "취소", "pt": "Cancelar", "ar": "إلغاء"],
        "settingsRemove": ["en": "Remove", "ru": "", "es": "Eliminar", "fr": "Supprimer"],
        "settingsDelete": ["en": "Delete", "ru": "", "es": "Eliminar", "fr": "Supprimer", "de": "Löschen", "zh": "删除", "ja": "削除", "ko": "삭제", "pt": "Eliminar", "ar": "حذف"],
        "settingsArchive": ["en": "Archive", "ru": "", "es": "Archivar", "fr": "Archiver", "de": "Archivieren", "zh": "归档", "ja": "アーカイブ", "ko": "보관", "pt": "Arquivar", "ar": "أرشفة"],
        "settingsRestore": ["en": "Restore", "ru": "", "es": "Restaurar", "fr": "Restaurer"],
        "settingsFindNewPath": ["en": "FindNewPath", "ru": ""],
        "settingsExportBackup": ["en": "ExportBackup", "ru": ""],
        "settingsImportBackup": ["en": "ImportBackup", "ru": ""],
        "settingsCompress": ["en": "Compress", "ru": "", "es": "Comprimir", "fr": "Compresser"],
        "settingsArchiveNow": ["en": "ArchiveNow", "ru": ""],
        "settingsDeleteOlderThan": ["en": "DeleteOlderThan", "ru": ""],
        "settingsTypeNameToConfirm": ["en": "TypeNameTo Confirm", "ru": ""],
        "settingsDeleteProjectDescription": ["en": "DeleteProject Description", "ru": ""],
        "settingsStorageQuotaExceeded": ["en": "StorageQuotaExceeded", "ru": ""],
        "settingsStorageQuotaDescription": ["en": "StorageQuota Description", "ru": ""],
        "settingsStorageQuotaArchiveInactive": ["en": "StorageQuotaArchiveInactive", "ru": ""],
        "settingsNoProjectsRegistered": ["en": "NoProjectsRegistered", "ru": ""],
        "settingsActive": ["en": "Active", "ru": "", "es": "Activo", "fr": "Actif", "de": "Aktiv", "zh": "活跃", "ja": "アクティブ", "ko": "활성", "pt": "Ativo", "ar": "نشط"],
        "settingsArchived": ["en": "Archived", "ru": "", "es": "Archivado", "fr": "Archivé", "de": "Archiviert", "zh": "已归档", "ja": "アーカイブ済み", "ko": "보관됨", "pt": "Arquivado", "ar": "مؤرشف"],
        "settingsOrphaned": ["en": "Orphaned", "ru": "", "es": "Huérfano", "fr": "Orphelin"],
        "settingsAutoArchiveDescription": ["en": "AutoArchive Description", "ru": ""],
        "settingsArchiveAfter": ["en": "ArchiveAfter", "ru": ""],
        "settingsCleanupTitle": ["en": "Cleanup Title", "ru": ""],
        "settingsCleanupDeleteChatsOlderThan": ["en": "CleanupDeleteChatsOlderThan", "ru": ""],
        "settingsDeleteButton": ["en": "Delete Button", "ru": "", "es": "Eliminar", "fr": "Bouton de suppression"],
        "settingsDeleteAllArchivedChats": ["en": "DeleteAllArchivedChats", "ru": ""],
        "settingsCompressDatabase": ["en": "CompressDatabase", "ru": ""],
        "settingsResetStorageTitle": ["en": "ResetStorage Title", "ru": ""],
        "settingsResetAppCache": ["en": "ResetAppCache", "ru": ""],
        "settingsClearAppCache": ["en": "ClearAppCache", "ru": ""],
        "settingsArchiveInactive": ["en": "ArchiveInactive", "ru": ""],
        "terminalTab": ["en": "Terminal", "ru": "Терминал", "es": "Terminal", "fr": "Terminal", "de": "Terminal", "zh": "终端", "ja": "ターミナル", "ko": "터미널", "pt": "Terminal", "ar": "الطرفية"],
        "gitTab": ["en": "Git", "ru": "Git", "es": "Git", "fr": "Git", "de": "Git", "zh": "Git", "ja": "Git", "ko": "Git", "pt": "Git", "ar": "Git"],
        "terminalWelcome": ["en": "Welcome to MiCoder Terminal", "ru": "Добро пожаловать в терминал MiCoder", "es": "Bienvenido al terminal de MiCoder", "fr": "Bienvenue dans le terminal MiCoder", "de": "Willkommen beim MiCoder-Terminal", "zh": "欢迎使用 MiCoder 终端", "ja": "MiCoder ターミナルへようこそ", "ko": "MiCoder 터미널에 오신 것을 환영합니다", "pt": "Bem-vindo ao MiCoder Terminal", "ar": "مرحبًا بك في طرفية MiCoder"],
        "terminalHelpOutput": ["en": "Available commands: clear, help, ls, pwd", "ru": "Доступные команды: clear, help, ls, pwd", "es": "Comandos disponibles: clear, help, ls, pwd", "fr": "Commandes disponibles : clear, help, ls, pwd", "de": "Verfügbare Befehle: clear, help, ls, pwd", "zh": "可用命令：clear、help、ls、pwd", "ja": "利用可能なコマンド: clear, help, ls, pwd", "ko": "사용 가능한 명령: clear, help, ls, pwd", "pt": "Comandos disponíveis: clear, help, ls, pwd", "ar": "الأوامر المتاحة: clear, help, ls, pwd"],
        "terminalCommandNotFound": ["en": "Command not found: %@", "ru": "Команда не найдена: %@", "es": "Comando no encontrado: %@", "fr": "Commande introuvable : %@", "de": "Befehl nicht gefunden: %@", "zh": "找不到命令：%@", "ja": "コマンドが見つかりません: %@", "ko": "명령을 찾을 수 없습니다: %@", "pt": "Comando não encontrado: %@", "ar": "الأمر غير موجود: %@"],
        "gitToolsTitle": ["en": "Git tools", "ru": "Инструменты Git", "es": "Herramientas de Git", "fr": "Outils Git", "de": "Git-Werkzeuge", "zh": "Git 工具", "ja": "Git ツール", "ko": "Git 도구", "pt": "Ferramentas Git", "ar": "أدوات Git"],
        "gitChanges": ["en": "Changes", "ru": "Изменения", "es": "Cambios", "fr": "Modifications", "de": "Änderungen", "zh": "更改", "ja": "変更", "ko": "변경 사항", "pt": "Alterações", "ar": "التغييرات"],
        "gitNoChanges": ["en": "No changes", "ru": "Нет изменений", "es": "Sin cambios", "fr": "Aucune modification", "de": "Keine Änderungen", "zh": "无更改", "ja": "変更なし", "ko": "변경 사항 없음", "pt": "Sem alterações", "ar": "لا توجد تغييرات"],
        "gitBranch": ["en": "Branch", "ru": "Ветка", "es": "Rama", "fr": "Branche", "de": "Zweig", "zh": "分支", "ja": "ブランチ", "ko": "브랜치", "pt": "Ramo", "ar": "الفرع"],
        "gitCommit": ["en": "Commit", "ru": "Коммит", "es": "Confirmación", "fr": "Valider", "de": "Commit", "zh": "提交", "ja": "コミット", "ko": "커밋", "pt": "Commit", "ar": "الالتزام"],
        "gitCommitAuto": ["en": "Auto-generate from changes", "ru": "Авто-создать из изменений", "es": "Generar automáticamente a partir de los cambios", "fr": "Générer automatiquement à partir des modifications", "de": "Automatisch aus Änderungen generieren", "zh": "从更改自动生成", "ja": "変更から自動生成", "ko": "변경 사항에서 자동 생성", "pt": "Gerar automaticamente a partir das alterações", "ar": "إنشاء تلقائي من التغييرات"],
        "gitCommitCustom": ["en": "Write custom message", "ru": "Написать своё сообщение", "es": "Escribir mensaje personalizado", "fr": "Écrire un message personnalisé", "de": "Benutzerdefinierte Nachricht schreiben", "zh": "编写自定义消息", "ja": "カスタムメッセージを書く", "ko": "사용자 정의 메시지 작성", "pt": "Escrever mensagem personalizada", "ar": "كتابة رسالة مخصصة"],
        "gitReviewPush": ["en": "Review & Push", "ru": "Обзор и пуш", "es": "Revisar y enviar", "fr": "Vérifier et pousser", "de": "Überprüfen & Pushen", "zh": "审查并推送", "ja": "レビューしてプッシュ", "ko": "검토 및 푸시", "pt": "Rever e Push", "ar": "مراجعة ودفع"],
        "gitPublish": ["en": "Publish", "ru": "Публикация", "es": "Publicar", "fr": "Publier", "de": "Veröffentlichen", "zh": "发布", "ja": "公開", "ko": "게시", "pt": "Publicar", "ar": "نشر"],
        "gitPublishTitle": ["en": "Publish to GitHub", "ru": "Опубликовать на GitHub", "es": "Publicar en GitHub", "fr": "Publier sur GitHub", "de": "Auf GitHub veröffentlichen", "zh": "发布到 GitHub", "ja": "GitHubに公開", "ko": "GitHub에 게시", "pt": "Publicar no GitHub", "ar": "النشر على GitHub"],
        "gitRepoName": ["en": "Repository name", "ru": "Имя репозитория", "es": "Nombre del repositorio", "fr": "Nom du dépôt", "de": "Repository-Name", "zh": "仓库名称", "ja": "リポジトリ名", "ko": "저장소 이름", "pt": "Nome do repositório", "ar": "اسم المستودع"],
        "gitInitTitle": ["en": "Initialize Git Repository", "ru": "Инициализировать Git репозиторий", "es": "Inicializar repositorio Git", "fr": "Initialiser le dépôt Git", "de": "Git-Repository initialisieren", "zh": "初始化 Git 仓库", "ja": "Git リポジトリを初期化", "ko": "Git 저장소 초기화", "pt": "Inicializar repositório Git", "ar": "تهيئة مستودع Git"],
        "gitVisibility": ["en": "Visibility", "ru": "Видимость", "es": "Visibilidad", "fr": "Visibilité", "de": "Sichtbarkeit", "zh": "可见性", "ja": "公開範囲", "ko": "공개 범위", "pt": "Visibilidade", "ar": "الظهور"],
        "gitPublic": ["en": "Public", "ru": "Публичный", "es": "Público", "fr": "Public", "de": "Öffentlich", "zh": "公开", "ja": "公開", "ko": "공개", "pt": "Público", "ar": "عام"],
        "gitPrivate": ["en": "Private", "ru": "Приватный", "es": "Privado", "fr": "Privé", "de": "Privat", "zh": "私有", "ja": "非公開", "ko": "비공개", "pt": "Privado", "ar": "خاص"],
        "gitInitialize": ["en": "Initialize", "ru": "Инициализировать", "es": "Inicializar", "fr": "Initialiser", "de": "Initialisieren", "zh": "初始化", "ja": "初期化", "ko": "초기화", "pt": "Inicializar", "ar": "تهيئة"],
        "gitPublishToGithub": ["en": "Publish to GitHub", "ru": "Опубликовать на GitHub", "es": "Publicar en GitHub", "fr": "Publier sur GitHub", "de": "Auf GitHub veröffentlichen", "zh": "发布到 GitHub", "ja": "GitHubに公開", "ko": "GitHub에 게시", "pt": "Publicar no GitHub", "ar": "النشر على GitHub"],
        "gitBusyRetrying": ["en": "Session busy, aborting and retrying...", "ru": "Сессия занята, отмена и повтор...", "es": "Sesión ocupada, cancelando y reintentando...", "fr": "Session occupée, abandon et nouvelle tentative...", "de": "Sitzung belegt, Abbruch und Wiederholung...", "zh": "会话繁忙，正在中止并重试...", "ja": "セッションがビジーです。中止して再試行しています...", "ko": "세션이 사용 중입니다. 중단 후 재시도하는 중...", "pt": "Sessão ocupada, a abortar e a tentar novamente...", "ar": "الجلسة مشغولة، يتم الإلغاء وإعادة المحاولة..."],
        "gitInstallGHTitle": ["en": "Install GitHub CLI", "ru": "Установить GitHub CLI", "es": "Instalar GitHub CLI", "fr": "Installer GitHub CLI", "de": "GitHub CLI installieren", "zh": "安装 GitHub CLI", "ja": "GitHub CLIをインストール", "ko": "GitHub CLI 설치", "pt": "Instalar GitHub CLI", "ar": "تثبيت GitHub CLI"],
        "gitInstallGHSubtitle": ["en": "GitHub CLI (gh) is required to create repositories from MiMo. Install it with Homebrew, or open the docs to install manually.", "ru": "Для создания репозиториев из MiMo нужен GitHub CLI (gh). Установите его через Homebrew или откройте документацию для ручной установки.", "es": "Se requiere GitHub CLI (gh) para crear repositorios desde MiMo. Instálelo con Homebrew o abra la documentación.", "fr": "GitHub CLI (gh) est requis pour créer des dépôts depuis MiMo. Installez-le avec Homebrew ou ouvrez la documentation."],
        "gitInstallGHButton": ["en": "Install with Homebrew", "ru": "Установить через Homebrew", "es": "Instalar con Homebrew", "fr": "Installer avec Homebrew", "de": "Mit Homebrew installieren", "zh": "使用 Homebrew 安装", "ja": "Homebrewでインストール", "ko": "Homebrew로 설치", "pt": "Instalar com Homebrew", "ar": "التثبيت عبر Homebrew"],
        "gitSignInTitle": ["en": "Sign in to GitHub", "ru": "Войти в GitHub", "es": "Iniciar sesión en GitHub", "fr": "Se connecter à GitHub", "de": "Bei GitHub anmelden", "zh": "登录 GitHub", "ja": "GitHubにサインイン", "ko": "GitHub에 로그인", "pt": "Iniciar sessão no GitHub", "ar": "تسجيل الدخول إلى GitHub"],
        "gitSignInSubtitle": ["en": "Authorize GitHub CLI in your browser. A one-time code flow will open on github.com.", "ru": "Авторизуйте GitHub CLI в браузере. Откроется страница github.com с одноразовым кодом.", "es": "Autorice GitHub CLI en su navegador. Se abrirá un flujo de código único en github.com.", "fr": "Autorisez GitHub CLI dans votre navigateur. Un flux de code à usage unique s'ouvrira sur github.com."],
        "gitSignInButton": ["en": "Sign in with browser", "ru": "Войти через браузер", "es": "Iniciar sesión con el navegador", "fr": "Se connecter via le navigateur", "de": "Mit Browser anmelden", "zh": "使用浏览器登录", "ja": "ブラウザでサインイン", "ko": "브라우저로 로그인", "pt": "Iniciar sessão com o navegador", "ar": "تسجيل الدخول عبر المتصفح"],
        "gitCreateAndPush": ["en": "Create & Push", "ru": "Создать и запушить", "es": "Crear y enviar", "fr": "Créer et pousser", "de": "Erstellen & Pushen", "zh": "创建并推送", "ja": "作成してプッシュ", "ko": "생성 및 푸시", "pt": "Criar e Push", "ar": "إنشاء ودفع"],
        "gitCancel": ["en": "Cancel", "ru": "Отмена", "es": "Cancelar", "fr": "Annuler", "de": "Abbrechen", "zh": "取消", "ja": "キャンセル", "ko": "취소", "pt": "Cancelar", "ar": "إلغاء"],
        "gitInitSubtitle": ["en": "Create a local Git repository for this workspace. You can publish it to GitHub afterwards.", "ru": "Создать локальный Git-репозиторий для этого workspace. После этого его можно опубликовать на GitHub.", "es": "Cree un repositorio Git local para esta área de trabajo. Puede publicarlo en GitHub después.", "fr": "Créez un dépôt Git local pour cet espace de travail. Vous pourrez le publier sur GitHub par la suite.", "de": "Erstellen Sie ein lokales Git-Repository für diesen Arbeitsbereich. Sie können es anschließend auf GitHub veröffentlichen.", "zh": "为此工作区创建一个本地 Git 仓库。之后您可以将其发布到 GitHub。", "ja": "このワークスペース用のローカル Git リポジトリを作成します。後でGitHubに公開できます。", "ko": "이 작업 공간에 로컬 Git 저장소를 만듭니다. 나중에 GitHub에 게시할 수 있습니다.", "pt": "Crie um repositório Git local para esta área de trabalho. Pode publicá-lo no GitHub posteriormente.", "ar": "أنشئ مستودع Git محلي لمساحة العمل هذه. يمكنك نشره على GitHub لاحقًا."],
        "gitReviewComment": ["en": "Your comment", "ru": "Ваш комментарий", "es": "Su comentario", "fr": "Votre commentaire", "de": "Ihr Kommentar", "zh": "您的评论", "ja": "コメント", "ko": "내 댓글", "pt": "O seu comentário", "ar": "تعليقك"],
        "gitReviewCommentPlaceholder": ["en": "What did you change? (optional)", "ru": "Что вы изменили? (необязательно)", "es": "¿Qué cambió? (opcional)", "fr": "Qu'avez-vous modifié ? (facultatif)", "de": "Was haben Sie geändert? (optional)", "zh": "您更改了什么？（可选）", "ja": "何を変更しましたか？（任意）", "ko": "무엇을 변경했나요? (선택 사항)", "pt": "O que alterou? (opcional)", "ar": "ما الذي غيّرته؟ (اختياري)"],
        "gitReviewSummary": ["en": "Auto summary of changes", "ru": "Автосводка изменений", "es": "Resumen automático de cambios", "fr": "Résumé automatique des modifications", "de": "Automatische Zusammenfassung der Änderungen", "zh": "更改的自动摘要", "ja": "変更の自動要約", "ko": "변경 사항 자동 요약", "pt": "Resumo automático das alterações", "ar": "ملخص تلقائي للتغييرات"],
        "gitCommitAndPush": ["en": "Commit & Push", "ru": "Коммит и пуш", "es": "Confirmar y enviar", "fr": "Valider et pousser", "de": "Commit & Pushen", "zh": "提交并推送", "ja": "コミットしてプッシュ", "ko": "커밋 및 푸시", "pt": "Commit e Push", "ar": "التزام ودفع"],
        "gitOpenGitHubDocs": ["en": "Open install docs", "ru": "Открыть документацию", "es": "Abrir documentación de instalación", "fr": "Ouvrir la documentation d'installation", "de": "Installationsdokumentation öffnen", "zh": "打开安装文档", "ja": "インストールドキュメントを開く", "ko": "설치 문서 열기", "pt": "Abrir documentação de instalação", "ar": "فتح وثائق التثبيت"],
        "planTitle": ["en": "Plan", "ru": "План", "es": "Plan", "fr": "Plan", "de": "Plan", "zh": "计划", "ja": "プラン", "ko": "계획", "pt": "Plano", "ar": "الخطة"],
        "noStepsYet": ["en": "No steps yet", "ru": "Нет шагов", "es": "Sin pasos aún", "fr": "Aucune étape pour le moment", "de": "Noch keine Schritte", "zh": "暂无步骤", "ja": "まだステップがありません", "ko": "아직 단계가 없습니다", "pt": "Ainda sem passos", "ar": "لا توجد خطوات بعد"],
        "completedSteps": ["en": "%d completed", "ru": "%d завершено"],
        "waitingSteps": ["en": "%d waiting", "ru": "%d ожидает"],
        "appDisplayName": ["en": "MiCoder", "ru": "MiCoder"],
        "statusBarIdle": ["en": "Idle", "ru": "Ожидание", "es": "Inactivo", "fr": "Inactif", "de": "Leerlauf", "zh": "空闲", "ja": "アイドル", "ko": "대기 중", "pt": "Inativo", "ar": "خامل"],
        "statusBarGenerating": ["en": "Generating...", "ru": "Генерация...", "es": "Generando...", "fr": "Génération...", "de": "Wird generiert...", "zh": "正在生成...", "ja": "生成中...", "ko": "생성 중...", "pt": "A gerar...", "ar": "جارٍ الإنشاء..."],
        "statusBarProcessing": ["en": "Processing...", "ru": "Обработка...", "es": "Procesando...", "fr": "Traitement...", "de": "Wird verarbeitet...", "zh": "正在处理...", "ja": "処理中...", "ko": "처리 중...", "pt": "A processar...", "ar": "جارٍ المعالجة..."],
        "newProjectTitle": ["en": "New Project", "ru": "Новый проект", "es": "Nuevo proyecto", "fr": "Nouveau projet", "de": "Neues Projekt", "zh": "新建项目", "ja": "新規プロジェクト", "ko": "새 프로젝트", "pt": "Novo Projeto", "ar": "مشروع جديد"],
        "newProjectName": ["en": "Project Name", "ru": "Имя проекта", "es": "Nombre del proyecto", "fr": "Nom du projet", "de": "Projektname", "zh": "项目名称", "ja": "プロジェクト名", "ko": "프로젝트 이름", "pt": "Nome do Projeto", "ar": "اسم المشروع"],
        "newProjectFolder": ["en": "Folder", "ru": "Папка", "es": "Carpeta", "fr": "Dossier", "de": "Ordner", "zh": "文件夹", "ja": "フォルダー", "ko": "폴더", "pt": "Pasta", "ar": "المجلد"],
        "newProjectChooseFolder": ["en": "Choose Folder", "ru": "Выбрать папку", "es": "Elegir carpeta", "fr": "Choisir un dossier", "de": "Ordner wählen", "zh": "选择文件夹", "ja": "フォルダーを選択", "ko": "폴더 선택", "pt": "Escolher pasta", "ar": "اختر مجلدًا"],
        "newProjectCreate": ["en": "Create Project", "ru": "Создать проект", "es": "Crear proyecto", "fr": "Créer le projet", "de": "Projekt erstellen", "zh": "创建项目", "ja": "プロジェクトを作成", "ko": "프로젝트 생성", "pt": "Criar projeto", "ar": "إنشاء مشروع"],
        "newProjectCancel": ["en": "Cancel", "ru": "Отмена", "es": "Cancelar", "fr": "Annuler", "de": "Abbrechen", "zh": "取消", "ja": "キャンセル", "ko": "취소", "pt": "Cancelar", "ar": "إلغاء"],
        "notificationsTitle": ["en": "Notifications", "ru": "Уведомления", "es": "Notificaciones", "fr": "Notifications", "de": "Benachrichtigungen", "zh": "通知", "ja": "通知", "ko": "알림", "pt": "Notificações", "ar": "الإشعارات"],
        "notificationsEmpty": ["en": "No notifications", "ru": "Нет уведомлений", "es": "Sin notificaciones", "fr": "Aucune notification", "de": "Keine Benachrichtigungen", "zh": "暂无通知", "ja": "通知はありません", "ko": "알림 없음", "pt": "Sem notificações", "ar": "لا توجد إشعارات"],
        "notificationsEmptySubtitle": ["en": "Task completions and system alerts will appear here.", "ru": "Здесь будет история уведомлений и системных событий.", "es": "Las finalizaciones de tareas y alertas del sistema aparecerán aquí.", "fr": "Les fins de tâches et alertes système apparaîtront ici.", "de": "Aufgabenerledigungen und Systemwarnungen werden hier angezeigt.", "zh": "任务完成和系统提醒将显示在此处。", "ja": "タスク完了とシステムアラートがここに表示されます。", "ko": "작업 완료 및 시스템 알림이 여기에 표시됩니다.", "pt": "As conclusões de tarefas e os alertas do sistema aparecerão aqui.", "ar": "ستظهر هنا إكمالات المهام وتنبيهات النظام."],
        "workspacesTitle": ["en": "Workspaces", "ru": "Проекты", "es": "Áreas de trabajo", "fr": "Espaces de travail", "de": "Arbeitsbereiche", "zh": "工作区", "ja": "ワークスペース", "ko": "작업 공간", "pt": "Áreas de trabalho", "ar": "مساحات العمل"],
        "noTasksYet": ["en": "No tasks yet", "ru": "Пока нет задач", "es": "Sin tareas aún", "fr": "Aucune tâche pour le moment", "de": "Noch keine Aufgaben", "zh": "暂无任务", "ja": "まだタスクがありません", "ko": "아직 작업이 없습니다", "pt": "Ainda sem tarefas", "ar": "لا توجد مهام بعد"],
        "justNow": ["en": "now", "ru": "только что", "es": "ahora", "fr": "maintenant", "de": "jetzt", "zh": "刚刚", "ja": "たった今", "ko": "지금", "pt": "agora", "ar": "الآن"],
        "storageTabTitle": ["en": "Storage", "ru": "Хранилище", "es": "Almacenamiento", "fr": "Stockage", "de": "Speicher", "zh": "存储", "ja": "ストレージ", "ko": "저장소", "pt": "Armazenamento", "ar": "التخزين"],
        "storageStatsTitle": ["en": "Storage", "ru": "Хранилище", "es": "Almacenamiento", "fr": "Stockage", "de": "Speicher", "zh": "存储", "ja": "ストレージ", "ko": "저장소", "pt": "Armazenamento", "ar": "التخزين"],
        "storageDatabaseSize": ["en": "Database", "ru": "База данных", "es": "Base de datos", "fr": "Base de données", "de": "Datenbank", "zh": "数据库", "ja": "データベース", "ko": "데이터베이스", "pt": "Base de dados", "ar": "قاعدة البيانات"],
        "storageSnapshotSize": ["en": "Snapshots", "ru": "Снимки", "es": "Instantáneas", "fr": "Instantanés", "de": "Schnappschüsse", "zh": "快照", "ja": "スナップショット", "ko": "스냅샷", "pt": "Instantâneos", "ar": "اللقطات"],
        "storageMessageCount": ["en": "Messages", "ru": "Сообщений", "es": "Mensajes", "fr": "Messages", "de": "Nachrichten", "zh": "消息", "ja": "メッセージ", "ko": "메시지", "pt": "Mensagens", "ar": "الرسائل"],
        "storageActiveSessions": ["en": "Active sessions", "ru": "Активные сессии", "es": "Sesiones activas", "fr": "Sessions actives", "de": "Aktive Sitzungen", "zh": "活跃会话", "ja": "アクティブセッション", "ko": "활성 세션", "pt": "Sessões ativas", "ar": "الجلسات النشطة"],
        "storageArchivedSessions": ["en": "Archived sessions", "ru": "Архивные сессии", "es": "Sesiones archivadas", "fr": "Sessions archivées", "de": "Archivierte Sitzungen", "zh": "已归档会话", "ja": "アーカイブ済みセッション", "ko": "보관된 세션", "pt": "Sessões arquivadas", "ar": "الجلسات المؤرشفة"],
        "cleanupTitle": ["en": "Cleanup", "ru": "Очистка", "es": "Limpieza", "fr": "Nettoyage", "de": "Bereinigung", "zh": "清理", "ja": "クリーンアップ", "ko": "정리", "pt": "Limpeza", "ar": "التنظيف"],
        "deleteChatsOlderThan": ["en": "Delete chats older than:", "ru": "Удалить чаты старше:", "es": "Eliminar chats anteriores a:", "fr": "Supprimer les conversations de plus de :", "de": "Chats löschen, die älter sind als:", "zh": "删除早于以下时间的聊天：", "ja": "次の日数より古いチャットを削除:", "ko": "다음보다 오래된 채팅 삭제:", "pt": "Eliminar conversas com mais de:", "ar": "حذف المحادثات الأقدم من:"],
        "deleteChats7Days": ["en": "7 days", "ru": "7 дней", "es": "7 días", "fr": "7 jours", "de": "7 Tage", "zh": "7 天", "ja": "7日", "ko": "7일", "pt": "7 dias", "ar": "7 أيام"],
        "deleteChats30Days": ["en": "30 days", "ru": "30 дней", "es": "30 días", "fr": "30 jours", "de": "30 Tage", "zh": "30 天", "ja": "30日", "ko": "30일", "pt": "30 dias", "ar": "30 يومًا"],
        "deleteChats90Days": ["en": "90 days", "ru": "90 дней", "es": "90 días", "fr": "90 jours", "de": "90 Tage", "zh": "90 天", "ja": "90日", "ko": "90일", "pt": "90 dias", "ar": "90 يومًا"],
        "deleteChats180Days": ["en": "180 days", "ru": "180 дней", "es": "180 días", "fr": "180 jours", "de": "180 Tage", "zh": "180 天", "ja": "180日", "ko": "180일", "pt": "180 dias", "ar": "180 يومًا"],
        "deleteChats1Year": ["en": "1 year", "ru": "1 год", "es": "1 año", "fr": "1 an", "de": "1 Jahr", "zh": "1 年", "ja": "1年", "ko": "1년", "pt": "1 ano", "ar": "سنة واحدة"],
        "deleteChatsConfirmTitle": ["en": "Delete old chats?", "ru": "Удалить старые чаты?", "es": "¿Eliminar chats antiguos?", "fr": "Supprimer les anciennes conversations ?", "de": "Alte Chats löschen?", "zh": "删除旧聊天？", "ja": "古いチャットを削除しますか？", "ko": "오래된 채팅을 삭제하시겠습니까?", "pt": "Eliminar conversas antigas?", "ar": "هل تريد حذف المحادثات القديمة؟"],
        "deleteChatsConfirmMessage": ["en": "This will permanently delete all chats older than %d days, including their messages. This action cannot be undone.", "ru": "Это навсегда удалит все чаты старше %d дней со всеми сообщениями. Действие нельзя отменить.", "es": "Esto eliminará permanentemente todos los chats anteriores a %d días, incluidos sus mensajes. Esta acción no se puede deshacer.", "fr": "Cela supprimera définitivement toutes les conversations de plus de %d jours, y compris leurs messages. Cette action est irréversible.", "de": "Dies löscht dauerhaft alle Chats, die älter als %d Tage sind, einschließlich ihrer Nachrichten. Diese Aktion kann nicht rückgängig gemacht werden.", "zh": "这将永久删除所有早于 %d 天的聊天及其消息。此操作无法撤销。", "ja": "%d日より古いすべてのチャット（メッセージ含む）が完全に削除されます。この操作は元に戻せません。", "ko": "%d일보다 오래된 모든 채팅(메시지 포함)이 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.", "pt": "Isto eliminará permanentemente todas as conversas com mais de %d dias, incluindo as suas mensagens. Esta ação não pode ser anulada.", "ar": "سيؤدي هذا إلى حذف جميع المحادثات الأقدم من %d يومًا بشكل دائم، بما في ذلك رسائلها. لا يمكن التراجع عن هذا الإجراء."],
        "deleteButton": ["en": "Delete", "ru": "Удалить", "es": "Eliminar", "fr": "Supprimer", "de": "Löschen", "zh": "删除", "ja": "削除", "ko": "삭제", "pt": "Eliminar", "ar": "حذف"],
        "cancelButton": ["en": "Cancel", "ru": "Отмена", "es": "Cancelar", "fr": "Annuler", "de": "Abbrechen", "zh": "取消", "ja": "キャンセル", "ko": "취소", "pt": "Cancelar", "ar": "إلغاء"],
        "deleteAllArchivedChats": ["en": "Delete all archived chats", "ru": "Удалить все архивные чаты", "es": "Eliminar todos los chats archivados", "fr": "Supprimer toutes les conversations archivées", "de": "Alle archivierten Chats löschen", "zh": "删除所有已归档的聊天", "ja": "すべてのアーカイブ済みチャットを削除", "ko": "보관된 모든 채팅 삭제", "pt": "Eliminar todas as conversas arquivadas", "ar": "حذف جميع المحادثات المؤرشفة"],
        "compressDatabase": ["en": "Compress database (VACUUM)", "ru": "Сжать базу (VACUUM)", "es": "Comprimir base de datos (VACUUM)", "fr": "Compresser la base de données (VACUUM)", "de": "Datenbank komprimieren (VACUUM)", "zh": "压缩数据库 (VACUUM)", "ja": "データベースを圧縮 (VACUUM)", "ko": "데이터베이스 압축(VACUUM)", "pt": "Comprimir base de dados (VACUUM)", "ar": "ضغط قاعدة البيانات (VACUUM)"],
        "resetStorageTitle": ["en": "Reset storage", "ru": "Сброс хранилища", "es": "Restablecer almacenamiento", "fr": "Réinitialiser le stockage", "de": "Speicher zurücksetzen", "zh": "重置存储", "ja": "ストレージをリセット", "ko": "저장소 재설정", "pt": "Repor armazenamento", "ar": "إعادة تعيين التخزين"],
        "resetAppCache": ["en": "Clear app cache", "ru": "Очистить кеш приложения", "es": "Borrar caché de la aplicación", "fr": "Vider le cache de l'application", "de": "App-Cache leeren", "zh": "清除应用缓存", "ja": "アプリキャッシュをクリア", "ko": "앱 캐시 지우기", "pt": "Limpar cache da aplicação", "ar": "مسح ذاكرة التخزين المؤقت للتطبيق"],
        "resetAppCacheConfirmTitle": ["en": "Clear app cache?", "ru": "Очистить кеш приложения?", "es": "¿Borrar caché de la aplicación?", "fr": "Vider le cache de l'application ?", "de": "App-Cache leeren?", "zh": "清除应用缓存？", "ja": "アプリキャッシュをクリアしますか？", "ko": "앱 캐시를 지우시겠습니까?", "pt": "Limpar cache da aplicação?", "ar": "هل تريد مسح ذاكرة التخزين المؤقت للتطبيق؟"],
        "resetButton": ["en": "Reset", "ru": "Сбросить", "es": "Restablecer", "fr": "Réinitialiser", "de": "Zurücksetzen", "zh": "重置", "ja": "リセット", "ko": "재설정", "pt": "Repor", "ar": "إعادة تعيين"],
        "archiveNow": ["en": "Archive now", "ru": "Архивировать сейчас", "es": "Archivar ahora", "fr": "Archiver maintenant", "de": "Jetzt archivieren", "zh": "立即归档", "ja": "今すぐアーカイブ", "ko": "지금 보관", "pt": "Arquivar agora", "ar": "أرشفة الآن"],
    ]
}
