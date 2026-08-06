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
    // Code Preview
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
    // Model Settings
    case settingsModelSettingsTitle
    case settingsModelSettingsDescription
    // Skills
    case settingsSkillsTitle
    case settingsSkillsDescription
    case settingsSearchSkillsPlaceholder
    case settingsNoSkillsInstalled
    case settingsNoSkillsInstalledSubtitle
    // MCP Servers
    case settingsMCPServersTitle
    case settingsMCPServersDescription
    case settingsSearchMCPServersPlaceholder
    case settingsNoMCPServersConfigured
    case settingsNoMCPServersConfiguredSubtitle
    // Plugins
    case settingsPluginsTitle
    case settingsPluginsDescription
    case settingsSearchPluginsPlaceholder
    case settingsNoPluginsInstalled
    case settingsNoPluginsInstalledSubtitle
    case settingsEnabled
    case settingsDisabled
    // Commands
    case settingsCommandsTitle
    case settingsCommandsDescription
    case settingsSearchCommandsPlaceholder
    case settingsNoUserCommands
    case settingsNoUserCommandsSubtitle
    // Indexing
    case settingsIndexingTitle
    case settingsIndexingCodebaseTitle
    case settingsIndexNewFoldersTitle
    case settingsIndexNewFoldersDescription
    case settingsIndexRepositoriesTitle
    case settingsIndexRepositoriesDescription
    // Storage - already mostly localized, add missing
    case settingsStorageTitle
    // Usage
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
    // Local Providers
    case settingsLocalProvidersTitle
    case settingsLocalProvidersDescription
    case settingsLocalProvidersAddressPlaceholder
    case settingsLocalProvidersAutoDetect
    case settingsLocalProvidersDetecting
    case settingsLocalProvidersAdded
    case settingsLocalProvidersAdd
    case settingsLocalProvidersEnabled
    case settingsLocalProvidersDisabled
    // Providers Settings
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
    // Common
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
        // Code Preview
        case .settingsCodePreviewTitle:
            return [.spanish: "Vista de código", .french: "Aperçu du code", .german: "Code-Vorschau",
                    .chineseSimplified: "代码预览", .japanese: "コードプレビュー", .korean: "코드 미리보기", .portuguese: "Prévia do código", .arabic: "معاينة الكود"]
        case .settingsLightCodeThemeTitle:
            return [.spanish: "Tema claro de código", .french: "Thème de code clair", .german: "Helles Code-Design",
                    .chineseSimplified: "浅色代码主题", .japanese: "明るいコードテーマ", .korean: "밝은 코드 테마", .portuguese: "Tema claro de código", .arabic: "سمة الكود الفاتحة"]
        case .settingsLightCodeThemeDescription:
            return [.spanish: "Tema usado para bloques de código en modo claro.", .french: "Thème utilisé pour les blocs de code en mode clair.", .german: "Design für Codeblöcke im hellen Modus.",
                    .chineseSimplified: "浅色模式下代码块使用的主题。", .japanese: "ライトモード時のコードブロックで使用されるテーマ。", .korean: "라이트 모드에서 코드 블록에 사용되는 테마입니다.", .portuguese: "Tema usado para blocos de código no modo claro.", .arabic: "السمة المستخدمة لكتل الكود في الوضع الفاتح."]
        case .settingsDarkCodeThemeTitle:
            return [.spanish: "Tema oscuro de código", .french: "Thème de code sombre", .german: "Dunkles Code-Design",
                    .chineseSimplified: "深色代码主题", .japanese: "暗いコードテーマ", .korean: "어두운 코드 테마", .portuguese: "Tema escuro de código", .arabic: "سمة الكود الداكنة"]
        case .settingsDarkCodeThemeDescription:
            return [.spanish: "Tema usado para bloques de código en modo oscuro.", .french: "Thème utilisé pour les blocs de code en mode sombre.", .german: "Design für Codeblöcke im dunklen Modus.",
                    .chineseSimplified: "深色模式下代码块使用的主题。", .japanese: "ダークモード時のコードブロックで使用されるテーマ。", .korean: "다크 모드에서 코드 블록에 사용되는 테마입니다.", .portuguese: "Tema usado para blocos de código no modo escuro.", .arabic: "السمة المستخدمة لكتل الكود في الوضع الداكن."]
        case .settingsShowLineNumbersTitle:
            return [.spanish: "Mostrar números de línea", .french: "Afficher les numéros de ligne", .german: "Zeilennummern anzeigen",
                    .chineseSimplified: "显示行号", .japanese: "行番号を表示", .korean: "줄 번호 표시", .portuguese: "Mostrar números de linha", .arabic: "إظهار أرقام الأسطر"]
        case .settingsShowLineNumbersDescription:
            return [.spanish: "Mostrar números de línea en vistas previas de código.", .french: "Afficher les numéros de ligne dans les aperçus de code.", .german: "Zeilennummern in Codevorschauen anzeigen.",
                    .chineseSimplified: "在代码预览中显示行号。", .japanese: "コードプレビューに行番号を表示します。", .korean: "코드 미리보기에 줄 번호를 표시합니다.", .portuguese: "Exibir números de linha nas visualizações de código.", .arabic: "إظهار أرقام الأسطر في معاينات الكود."]
        case .settingsWrapLongLinesTitle:
            return [.spanish: "Ajustar líneas largas", .french: "Ajuster les lignes longues", .german: "Lange Zeilen umbrechen",
                    .chineseSimplified: "换行长行", .japanese: "長い行を折り返す", .korean: "긴 줄 줄바꿈", .portuguese: "Quebrar linhas longas", .arabic: "تفكيك الأسطر الطويلة"]
        case .settingsWrapLongLinesDescription:
            return [.spanish: "Ajustar automáticamente el contenido largo dentro del área de vista previa.", .french: "Ajuster automatiquement le contenu long dans la zone d'aperçu.", .german: "Lange Inhalte im Vorschau Bereich automatisch umbrechen.",
                    .chineseSimplified: "自动在预览区域内换行长内容。", .japanese: "プレビュー領域内で長いコンテンツを自動的に折り返します。", .korean: "미리보기 영역에서 긴 콘텐츠를 자동으로 줄바꿈합니다.", .portuguese: "Quebrar automaticamente conteúdo longo dentro da área de visualização.", .arabic: "تفكيك المحتوى الطويل تلقائيًا داخل منطقة المعاينة."]
        case .settingsCodeFontSizeTitle:
            return [.spanish: "Tamaño de fuente de código", .french: "Taille de police du code", .german: "Code-Schriftgröße",
                    .chineseSimplified: "代码字体大小", .japanese: "コードフォントサイズ", .korean: "코드 글꼴 크기", .portuguese: "Tamanho da fonte do código", .arabic: "حجم خط الكود"]
        case .settingsCodeFontSizeDescription:
            return [.spanish: "Ajusta el tamaño de fuente predeterminado usado por las vistas previas de código.", .french: "Ajustez la taille de police par défaut utilisée par les aperçus de code.", .german: "Passen Sie die Standard-Schriftgröße an, die von Codevorschauen verwendet wird.",
                    .chineseSimplified: "调整代码预览使用的默认字体大小。", .japanese: "コードプレビューで使用されるデフォルトのフォントサイズを調整します。", .korean: "코드 미리보기에서 사용하는 기본 글꼴 크기를 조정합니다.", .portuguese: "Ajuste o tamanho da fonte padrão usado pelas visualizações de código.", .arabic: "ضبط حجم الخط الافتراضي المستخدم بمعاينات الكود."]
        // Model Settings
        case .settingsModelSettingsTitle:
            return [.spanish: "Configuración de modelos", .french: "Configuration des modèles", .german: "Modell-Einstellungen",
                    .chineseSimplified: "模型设置", .japanese: "モデル設定", .korean: "모델 설정", .portuguese: "Configurações de modelos", .arabic: "إعدادات النماذج"]
        case .settingsModelSettingsDescription:
            return [.spanish: "Configura proveedores de modelos y gestiona modelos disponibles.", .french: "Configurez les fournisseurs de modèles et gérez les modèles disponibles.", .german: "Modellanbieter konfigurieren und verfügbare Modelle verwalten.",
                    .chineseSimplified: "配置模型提供商并管理可用模型。", .japanese: "モデルプロバイダーを設定し、利用可能なモデルを管理します。", .korean: "모델 공급자를 구성하고 사용 가능한 모델을 관리합니다.", .portuguese: "Configure provedores de modelos e gerencie modelos disponíveis.", .arabic: "قم بتكوين موفري النماذج وإدارة النماذج المتاحة."]
        // Skills
        case .settingsSkillsTitle:
            return [.spanish: "Habilidades", .french: "Compétences", .german: "Skills",
                    .chineseSimplified: "技能", .japanese: "スキル", .korean: "스킬", .portuguese: "Habilidades", .arabic: "المهارات"]
        case .settingsSkillsDescription:
            return [.spanish: "Explora la biblioteca e instala habilidades con un clic, o gestiona habilidades locales en ~/.micoder/skills.", .french: "Parcourez la bibliothèque et installez des compétences en un clic, ou gérez les compétences locales sous ~/.micoder/skills.", .german: "Durchsuchen Sie die Bibliothek und installieren Sie Skills mit einem Klick, oder verwalten Sie lokale Skills unter ~/.micoder/skills.",
                    .chineseSimplified: "浏览库并一键安装技能，或管理 ~/.micoder/skills 下的本地技能。", .japanese: "ライブラリを閲覧してワンクリックでスキルをインストール、または ~/.micoder/skills のローカルスキルを管理します。", .korean: "라이브러리를 탐색하고 한 번 클릭으로 스킬을 설치하거나 ~/.micoder/skills의 로컬 스킬을 관리합니다.", .portuguese: "Navegue pela biblioteca e instale skills com um clique, ou gerencie skills locais em ~/.micoder/skills.", .arabic: "تصفح المكتبة وثبت المهارات بنقرة واحدة، أو ادارة المهارات المحلية في ~/.micoder/skills."]
        case .settingsSearchSkillsPlaceholder:
            return [.spanish: "Buscar habilidades...", .french: "Rechercher des compétences...", .german: "Skills suchen...",
                    .chineseSimplified: "搜索技能...", .japanese: "スキルを検索...", .korean: "스킬 검색...", .portuguese: "Buscar skills...", .arabic: "البحث عن مهارات..."]
        case .settingsNoSkillsInstalled:
            return [.spanish: "No hay habilidades instaladas", .french: "Aucune compétence installée", .german: "Keine Skills installiert",
                    .chineseSimplified: "未安装技能", .japanese: "インストールされたスキルなし", .korean: "설치된 스킬 없음", .portuguese: "Nenhum skill instalado", .arabic: "لا توجد مهارات مثبتة"]
        case .settingsNoSkillsInstalledSubtitle:
            return [.spanish: "Elige una habilidad de la biblioteca de arriba y pulsa Instalar.", .french: "Choisissez une compétence dans la bibliothèque ci-dessus et cliquez sur Installer.", .german: "Wählen Sie einen Skill aus der Bibliothek oben und klicken Sie auf Installieren.",
                    .chineseSimplified: "从上方的库中选择一个技能并点击安装。", .japanese: "上のライブラリからスキルを選んでインストールを押してください。", .korean: "위의 라이브러리에서 스킬을 선택하고 설치를 누르세요.", .portuguese: "Escolha um skill da biblioteca acima e clique em Instalar.", .arabic: "اختر مهارة من المكتبة أعلاه واضغط تثبيت."]
        // MCP Servers
        case .settingsMCPServersTitle:
            return [.spanish: "Servidores MCP", .french: "Serveurs MCP", .german: "MCP-Server",
                    .chineseSimplified: "MCP 服务器", .japanese: "MCP サーバー", .korean: "MCP 서버", .portuguese: "Servidores MCP", .arabic: "خوادم MCP"]
        case .settingsMCPServersDescription:
            return [.spanish: "Explora la biblioteca e instala servidores MCP con un clic. Las configuraciones se guardan en ~/.micoder/mcp.json.", .french: "Parcourez la bibliothèque et installez des serveurs MCP en un clic. Les configurations sont enregistrées dans ~/.micoder/mcp.json.", .german: "Durchsuchen Sie die Bibliothek und installieren Sie MCP-Server mit einem Klick. Konfigurationen werden in ~/.micoder/mcp.json gespeichert.",
                    .chineseSimplified: "浏览库并一键安装 MCP 服务器。配置保存在 ~/.micoder/mcp.json。", .japanese: "ライブラリを閲覧してワンクリックで MCP サーバーをインストール。設定は ~/.micoder/mcp.json に保存されます。", .korean: "라이브러리를 탐색하고 한 번 클릭으로 MCP 서버를 설치합니다. 설정은 ~/.micoder/mcp.json에 저장됩니다.", .portuguese: "Navegue pela biblioteca e instale servidores MCP com um clique. Configurações são salvas em ~/.micoder/mcp.json.", .arabic: "تصفح المكتبة وثبت خوادم MCP بنقرة واحدة. يتم حفظ التكوينات في ~/.micoder/mcp.json."]
        case .settingsSearchMCPServersPlaceholder:
            return [.spanish: "Buscar servidores MCP...", .french: "Rechercher des serveurs MCP...", .german: "MCP-Server suchen...",
                    .chineseSimplified: "搜索 MCP 服务器...", .japanese: "MCP サーバーを検索...", .korean: "MCP 서버 검색...", .portuguese: "Buscar servidores MCP...", .arabic: "البحث عن خوادم MCP..."]
        case .settingsNoMCPServersConfigured:
            return [.spanish: "No hay servidores MCP configurados", .french: "Aucun serveur MCP configuré", .german: "Keine MCP-Server konfiguriert",
                    .chineseSimplified: "未配置 MCP 服务器", .japanese: "設定された MCP サーバーなし", .korean: "구성된 MCP 서버 없음", .portuguese: "Nenhum servidor MCP configurado", .arabic: "لا توجد خوادم MCP مهيأة"]
        case .settingsNoMCPServersConfiguredSubtitle:
            return [.spanish: "Elige un servidor de la biblioteca de arriba y pulsa Instalar.", .french: "Choisissez un serveur dans la bibliothèque ci-dessus et cliquez sur Installer.", .german: "Wählen Sie einen Server aus der Bibliothek oben und klicken Sie auf Installieren.",
                    .chineseSimplified: "从上方的库中选择一个服务器并点击安装。", .japanese: "上のライブラリからサーバーを選んでインストールを押してください。", .korean: "위의 라이브러리에서 서버를 선택하고 설치를 누르세요.", .portuguese: "Escolha um servidor da biblioteca acima e clique em Instalar.", .arabic: "اختر خادم من المكتبة أعلاه واضغط تثبيت."]
        // Plugins
        case .settingsPluginsTitle:
            return [.spanish: "Complementos", .french: "Extensions", .german: "Plugins",
                    .chineseSimplified: "插件", .japanese: "プラグイン", .korean: "플러그인", .portuguese: "Plugins", .arabic: "الإضافات"]
        case .settingsPluginsDescription:
            return [.spanish: "Activa o desactiva complementos instalados. Los complementos agrupan habilidades, comandos y servidores MCP.", .french: "Activez ou désactivez les extensions installées. Les extensions regroupent compétences, commandes et serveurs MCP.", .german: "Aktivieren oder deaktivieren Sie installierte Plugins. Plugins bündeln Skills, Befehle und MCP-Server.",
                    .chineseSimplified: "启用或禁用已安装的插件。插件捆绑技能、命令和 MCP 服务器。", .japanese: "インストール済みプラグインを有効/無効化します。プラグインはスキル、コマンド、MCPサーバーをバンドルします。", .korean: "설치된 플러그인을 활성화 또는 비활성화합니다. 플러그인은 스킬, 명령, MCP 서버를 번들로 제공합니다.", .portuguese: "Ative ou desative plugins instalados. Plugins agrupam skills, comandos e servidores MCP.", .arabic: "قم بتمكين أو تعطيل الإضافات المثبتة. الإضافات تجمع المهارات والأوامر وخوادم MCP."]
        case .settingsSearchPluginsPlaceholder:
            return [.spanish: "Buscar complementos...", .french: "Rechercher des extensions...", .german: "Plugins suchen...",
                    .chineseSimplified: "搜索插件...", .japanese: "プラグインを検索...", .korean: "플러그인 검색...", .portuguese: "Buscar plugins...", .arabic: "البحث عن إضافات..."]
        case .settingsNoPluginsInstalled:
            return [.spanish: "No hay complementos instalados", .french: "Aucune extension installée", .german: "Keine Plugins installiert",
                    .chineseSimplified: "未安装插件", .japanese: "インストールされたプラグインなし", .korean: "설치된 플러그인 없음", .portuguese: "Nenhum plugin instalado", .arabic: "لا توجد إضافات مثبتة"]
        case .settingsNoPluginsInstalledSubtitle:
            return [.spanish: "Los complementos están en ~/.micoder/plugins", .french: "Les extensions sont dans ~/.micoder/plugins", .german: "Plugins liegen in ~/.micoder/plugins",
                    .chineseSimplified: "插件位于 ~/.micoder/plugins", .japanese: "プラグインは ~/.micoder/plugins にあります", .korean: "플러그인은 ~/.micoder/plugins에 있습니다", .portuguese: "Plugins ficam em ~/.micoder/plugins", .arabic: "الإضافات في ~/.micoder/plugins"]
        case .settingsEnabled:
            return [.spanish: "Activado", .french: "Activé", .german: "Aktiviert",
                    .chineseSimplified: "已启用", .japanese: "有効", .korean: "활성화됨", .portuguese: "Ativado", .arabic: "مفعّل"]
        case .settingsDisabled:
            return [.spanish: "Desactivado", .french: "Désactivé", .german: "Deaktiviert",
                    .chineseSimplified: "已禁用", .japanese: "無効", .korean: "비활성화됨", .portuguese: "Desativado", .arabic: "معطّل"]
        // Commands
        case .settingsCommandsTitle:
            return [.spanish: "Comandos", .french: "Commandes", .german: "Befehle",
                    .chineseSimplified: "命令", .japanese: "コマンド", .korean: "명령", .portuguese: "Comandos", .arabic: "الأوامر"]
        case .settingsCommandsDescription:
            return [.spanish: "Gestiona archivos de comandos .md del Agente MiCoder. Los comandos se invocan con /nombre-comando en el chat.", .french: "Gérez les fichiers de commandes .md de l'Agent MiCoder. Les commandes s'invoquent avec /nom-commande dans le chat.", .german: "Verwalten Sie .md Befehlsdateien des MiCoder Agent. Befehle werden mit /befehlsname im Chat aufgerufen.",
                    .chineseSimplified: "管理 MiCoder Agent .md 命令文件。在聊天中使用 /命令名 调用命令。", .japanese: "MiCoder Agent の .md コマンドファイルを管理します。チャットで /コマンド名 で呼び出せます。", .korean: "MiCoder Agent .md 명령 파일을 관리합니다. 채팅에서 /명령어-이름으로 호출합니다.", .portuguese: "Gerencie arquivos de comando .md do Agente MiCoder. Comandos são invocados com /nome-do-comando no chat.", .arabic: "إدارة ملفات أوامر .md لوكيل MiCoder. يتم استدعاء الأوامر بـ /اسم-الأمر في الدردشة."]
        case .settingsSearchCommandsPlaceholder:
            return [.spanish: "Buscar comandos...", .french: "Rechercher des commandes...", .german: "Befehle suchen...",
                    .chineseSimplified: "搜索命令...", .japanese: "コマンドを検索...", .korean: "명령 검색...", .portuguese: "Buscar comandos...", .arabic: "البحث عن أوامر..."]
        case .settingsNoUserCommands:
            return [.spanish: "No hay comandos de usuario", .french: "Aucune commande utilisateur", .german: "Keine Benutzerbefehle",
                    .chineseSimplified: "无用户命令", .japanese: "ユーザーコマンドなし", .korean: "사용자 명령 없음", .portuguese: "Nenhum comando de usuário", .arabic: "لا توجد أوامر مستخدم"]
        case .settingsNoUserCommandsSubtitle:
            return [.spanish: "Añade archivos .md a ~/.micoder/commands", .french: "Ajoutez des fichiers .md à ~/.micoder/commands", .german: "Fügen Sie .md Dateien zu ~/.micoder/commands hinzu",
                    .chineseSimplified: "添加 .md 文件到 ~/.micoder/commands", .japanese: "~/.micoder/commands に .md ファイルを追加", .korean: "~/.micoder/commands에 .md 파일 추가", .portuguese: "Adicione arquivos .md em ~/.micoder/commands", .arabic: "أضف ملفات .md إلى ~/.micoder/commands"]
        // Indexing
        case .settingsIndexingTitle:
            return [.spanish: "Indexación", .french: "Indexation", .german: "Indizierung",
                    .chineseSimplified: "索引", .japanese: "インデックス", .korean: "인덱싱", .portuguese: "Indexação", .arabic: "الفهرسة"]
        case .settingsIndexingCodebaseTitle:
            return [.spanish: "Base de código", .french: "Base de code", .german: "Codebasis",
                    .chineseSimplified: "代码库", .japanese: "コードベース", .korean: "코드베이스", .portuguese: "Base de código", .arabic: "قاعدة الكود"]
        case .settingsIndexNewFoldersTitle:
            return [.spanish: "Indexar carpetas nuevas", .french: "Indexer les nouveaux dossiers", .german: "Neue Ordner indizieren",
                    .chineseSimplified: "索引新文件夹", .japanese: "新しいフォルダをインデックス", .korean: "새 폴더 인덱싱", .portuguese: "Indexar novas pastas", .arabic: "فهرسة المجلدات الجديدة"]
        case .settingsIndexNewFoldersDescription:
            return [.spanish: "Indexar automáticamente cualquier carpeta nueva con menos de 50,000 archivos.", .french: "Indexer automatiquement tout nouveau dossier comptant moins de 50 000 fichiers.", .german: "Neue Ordner mit weniger als 50.000 Dateien automatisch indizieren.",
                    .chineseSimplified: "自动索引少于 50,000 个文件的新文件夹。", .japanese: "50,000 ファイル未満の新しいフォルダを自動的にインデックスします。", .korean: "50,000개 미만의 파일이 있는 새 폴더를 자동으로 인덱싱합니다.", .portuguese: "Indexar automaticamente qualquer pasta nova com menos de 50.000 arquivos.", .arabic: "فهرسة أي مجلد جديد تلقائيًا إذا كان يحتوي على أقل من 50,000 ملف."]
        case .settingsIndexRepositoriesTitle:
            return [.spanish: "Indexar repositorios para grep instantáneo (Beta)", .french: "Indexer les dépôts pour grep instantané (Bêta)", .german: "Repositories für sofortiges Grep indizieren (Beta)",
                    .chineseSimplified: "为即时 grep 索引仓库 (Beta)", .japanese: "インスタント grep 用にリポジトリをインデックス (ベータ)", .korean: "즉시 grep을 위해 리포지토리 인덱싱 (베타)", .portuguese: "Indexar repositórios para grep instantâneo (Beta)", .arabic: "فهرسة المستودعات للبحث الفوري (تجريبي)"]
        case .settingsIndexRepositoriesDescription:
            return [.spanish: "Indexar automáticamente repositorios para acelerar búsquedas Grep. Todos los datos se almacenan localmente.", .french: "Indexer automatiquement les dépôts pour accélérer les recherches Grep. Toutes les données sont stockées localement.", .german: "Repositories automatisch indizieren, um Grep-Suchen zu beschleunigen. Alle Daten werden lokal gespeichert.",
                    .chineseSimplified: "自动索引仓库以加速 Grep 搜索。所有数据本地存储。", .japanese: "リポジトリを自動的にインデックスして grep 検索を高速化。すべてのデータはローカルに保存されます。", .korean: "Grep 검색 속도를 높이기 위해 리포지토리를 자동으로 인덱싱합니다. 모든 데이터는 로컬에 저장됩니다.", .portuguese: "Indexar repositórios automaticamente para acelerar buscas Grep. Todos os dados são armazenados localmente.", .arabic: "فهرسة المستودعات تلقائيًا لتسريع بحث Grep. جميع البيانات مخزنة محليًا."]
        // Usage
        case .settingsUsageTitle:
            return [.spanish: "Uso", .french: "Utilisation", .german: "Nutzung",
                    .chineseSimplified: "使用情况", .japanese: "使用状況", .korean: "사용량", .portuguese: "Uso", .arabic: "الاستخدام"]
        case .settingsUsageSubtitle:
            return [.spanish: "Uso de la app", .french: "Utilisation de l'app", .german: "App-Nutzung",
                    .chineseSimplified: "App使用情况", .japanese: "アプリの使用状況", .korean: "앱 사용량", .portuguese: "Uso do app", .arabic: "استخدام التطبيق"]
        case .settingsUsageTimeRange:
            return [.spanish: "Rango de tiempo", .french: "Période", .german: "Zeitraum",
                    .chineseSimplified: "时间范围", .japanese: "期間", .korean: "기간", .portuguese: "Período", .arabic: "النطاق الزمني"]
        case .settingsUsageTotalTokens:
            return [.spanish: "Tokens totales", .french: "Total de jetons", .german: "Gesamte Tokens",
                    .chineseSimplified: "总 Token 数", .japanese: "総トークン数", .korean: "총 토큰 수", .portuguese: "Total de tokens", .arabic: "إجمالي الرموز"]
        case .settingsUsageTotalCost:
            return [.spanish: "Coste total", .french: "Coût total", .german: "Gesamtkosten",
                    .chineseSimplified: "总成本", .japanese: "総コスト", .korean: "총 비용", .portuguese: "Custo total", .arabic: "التكلفة الإجمالية"]
        case .settingsUsageMessages:
            return [.spanish: "Mensajes", .french: "Messages", .german: "Nachrichten",
                    .chineseSimplified: "消息数", .japanese: "メッセージ数", .korean: "메시지 수", .portuguese: "Mensagens", .arabic: "الرسائل"]
        case .settingsUsageActiveDays:
            return [.spanish: "Días activos", .french: "Jours actifs", .german: "Aktive Tage",
                    .chineseSimplified: "活跃天数", .japanese: "アクティブ日数", .korean: "활성 일수", .portuguese: "Dias ativos", .arabic: "الأيام النشطة"]
        case .settingsUsageDatabaseSize:
            return [.spanish: "Tamaño de la base de datos", .french: "Taille de la base de données", .german: "Datenbankgröße",
                    .chineseSimplified: "数据库大小", .japanese: "データベースサイズ", .korean: "데이터베이스 크기", .portuguese: "Tamanho do banco de dados", .arabic: "حجم قاعدة البيانات"]
        case .settingsUsageFavoriteModel:
            return [.spanish: "Modelo favorito", .french: "Modèle favori", .german: "Lieblingsmodell",
                    .chineseSimplified: "常用模型", .japanese: "よく使うモデル", .korean: "즐겨찾는 모델", .portuguese: "Modelo favorito", .arabic: "النموذج المفضل"]
        case .settingsUsageFavoriteModelSubtitle:
            return [.spanish: "por uso", .french: "par utilisation", .german: "nach Nutzung",
                    .chineseSimplified: "按使用量", .japanese: "使用量順", .korean: "사용량 기준", .portuguese: "por uso", .arabic: "حسب الاستخدام"]
        case .settingsUsageByModel:
            return [.spanish: "Por modelo", .french: "Par modèle", .german: "Nach Modell",
                    .chineseSimplified: "按模型", .japanese: "モデル別", .korean: "모델별", .portuguese: "Por modelo", .arabic: "حسب النموذج"]
        case .settingsUsageNoData:
            return [.spanish: "No hay datos de uso para el período seleccionado.", .french: "Aucune donnée d'utilisation pour la période sélectionnée.", .german: "Keine Nutzungsdaten für den ausgewählten Zeitraum.",
                    .chineseSimplified: "所选时期无使用数据。", .japanese: "選択期間の使用データがありません。", .korean: "선택한 기간의 사용 데이터가 없습니다.", .portuguese: "Sem dados de uso para o período selecionado.", .arabic: "لا توجد بيانات استخدام للفترة المحددة."]
        // Local Providers
        case .settingsLocalProvidersTitle:
            return [.spanish: "Proveedores locales", .french: "Fournisseurs locaux", .german: "Lokale Anbieter",
                    .chineseSimplified: "本地提供商", .japanese: "ローカルプロバイダー", .korean: "로컬 공급자", .portuguese: "Provedores locais", .arabic: "الموفرون المحليون"]
        case .settingsLocalProvidersDescription:
            return [.spanish: "Ejecuta modelos localmente vía Ollama, OpenCode o MiCoder CLI/Serve. Introduce una dirección para auto-detectar el proveedor y cargar sus modelos.", .french: "Exécutez des modèles localement via Ollama, OpenCode ou MiCoder CLI/Serve. Entrez une adresse pour détecter automatiquement le fournisseur et charger ses modèles.", .german: "Führen Sie Modelle lokal über Ollama, OpenCode oder MiCoder CLI/Serve aus. Geben Sie eine Adresse ein, um den Anbieter automatisch zu erkennen und seine Modelle zu laden.",
                    .chineseSimplified: "通过 Ollama、OpenCode 或 MiCoder CLI/Serve 在本地运行模型。输入地址以自动检测提供商并加载其模型。", .japanese: "Ollama、OpenCode、または MiCoder CLI/Serve でローカルにモデルを実行。アドレスを入力してプロバイダーを自動検出し、モデルを読み込みます。", .korean: "Ollama, OpenCode 또는 MiCoder CLI/Serve를 통해 로컬에서 모델을 실행합니다. 주소를 입력하여 공급자를 자동 감지하고 모델을 로드합니다.", .portuguese: "Execute modelos localmente via Ollama, OpenCode ou MiCoder CLI/Serve. Insira um endereço para detectar automaticamente o provedor e carregar seus modelos.", .arabic: "تشغيل النماذج محليًا عبر Ollama أو OpenCode أو MiCoder CLI/Serve. أدخل عنوانًا للكشف التلقائي عن الموفر وتحميل نماذجه."]
        case .settingsLocalProvidersAddressPlaceholder:
            return [.spanish: "localhost:11434 o 192.168.1.10:4096", .french: "localhost:11434 ou 192.168.1.10:4096", .german: "localhost:11434 oder 192.168.1.10:4096",
                    .chineseSimplified: "localhost:11434 或 192.168.1.10:4096", .japanese: "localhost:11434 または 192.168.1.10:4096", .korean: "localhost:11434 또는 192.168.1.10:4096", .portuguese: "localhost:11434 ou 192.168.1.10:4096", .arabic: "localhost:11434 أو 192.168.1.10:4096"]
        case .settingsLocalProvidersAutoDetect:
            return [.spanish: "Auto-detectar", .french: "Auto-détecter", .german: "Auto-erkennen",
                    .chineseSimplified: "自动检测", .japanese: "自動検出", .korean: "자동 감지", .portuguese: "Auto-detectar", .arabic: "كشف تلقائي"]
        case .settingsLocalProvidersDetecting:
            return [.spanish: "Detectando…", .french: "Détection…", .german: "Erkennen…",
                    .chineseSimplified: "检测中…", .japanese: "検出中…", .korean: "감지 중…", .portuguese: "Detectando…", .arabic: "جاري الكشف…"]
        case .settingsLocalProvidersAdded:
            return [.spanish: "Añadido", .french: "Ajouté", .german: "Hinzugefügt",
                    .chineseSimplified: "已添加", .japanese: "追加済み", .korean: "추가됨", .portuguese: "Adicionado", .arabic: "تمت الإضافة"]
        case .settingsLocalProvidersAdd:
            return [.spanish: "Añadir", .french: "Ajouter", .german: "Hinzufügen",
                    .chineseSimplified: "添加", .japanese: "追加", .korean: "추가", .portuguese: "Adicionar", .arabic: "إضافة"]
        case .settingsLocalProvidersEnabled:
            return [.spanish: "Activado", .french: "Activé", .german: "Aktiviert",
                    .chineseSimplified: "已启用", .japanese: "有効", .korean: "활성화됨", .portuguese: "Ativado", .arabic: "مفعّل"]
        case .settingsLocalProvidersDisabled:
            return [.spanish: "Desactivado", .french: "Désactivé", .german: "Deaktiviert",
                    .chineseSimplified: "已禁用", .japanese: "無効", .korean: "비활성화됨", .portuguese: "Desativado", .arabic: "معطّل"]
        // Providers Settings
        case .settingsProvidersTitle:
            return [.spanish: "Proveedores", .french: "Fournisseurs", .german: "Anbieter",
                    .chineseSimplified: "提供商", .japanese: "プロバイダー", .korean: "제공자", .portuguese: "Provedores", .arabic: "المزودون"]
        case .settingsProvidersDescription:
            return [.spanish: "Gestiona proveedores de modelos personalizados y ve proveedores conectados al servidor.", .french: "Gérez les fournisseurs de modèles personnalisés et voyez les fournisseurs connectés au serveur.", .german: "Verwalten Sie benutzerdefinierte Modellanbieter und sehen Sie serververbundene Anbieter.",
                    .chineseSimplified: "管理自定义模型提供商并查看服务器连接的提供商。", .japanese: "カスタムモデルプロバイダーを管理し、サーバー接続済みプロバイダーを表示します。", .korean: "사용자 정의 모델 공급자를 관리하고 서버 연결된 공급자를 확인합니다.", .portuguese: "Gerencie provedores de modelos personalizados e veja provedores conectados ao servidor.", .arabic: "إدارة موفري النماذج المخصصة وعرض الموفرين المتصلين بالخادم."]
        case .settingsProvidersStatsProviders:
            return [.spanish: "Proveedores", .french: "Fournisseurs", .german: "Anbieter",
                    .chineseSimplified: "提供商", .japanese: "プロバイダー", .korean: "공급자", .portuguese: "Provedores", .arabic: "المزودون"]
        case .settingsProvidersStatsModels:
            return [.spanish: "Modelos", .french: "Modèles", .german: "Modelle",
                    .chineseSimplified: "模型", .japanese: "モデル", .korean: "모델", .portuguese: "Modelos", .arabic: "النماذج"]
        case .settingsProvidersSearchPlaceholder:
            return [.spanish: "Buscar proveedores...", .french: "Rechercher des fournisseurs...", .german: "Anbieter suchen...",
                    .chineseSimplified: "搜索提供商...", .japanese: "プロバイダーを検索...", .korean: "공급자 검색...", .portuguese: "Buscar provedores...", .arabic: "البحث عن الموفرين..."]
        case .settingsProvidersAdd:
            return [.spanish: "Añadir", .french: "Ajouter", .german: "Hinzufügen",
                    .chineseSimplified: "添加", .japanese: "追加", .korean: "추가", .portuguese: "Adicionar", .arabic: "إضافة"]
        case .settingsProvidersNoProviders:
            return [.spanish: "No hay proveedores configurados", .french: "Aucun fournisseur configuré", .german: "Keine Anbieter konfiguriert",
                    .chineseSimplified: "未配置提供商", .japanese: "設定されたプロバイダーなし", .korean: "구성된 공급자 없음", .portuguese: "Nenhum provedor configurado", .arabic: "لا توجد موفرين مهيأين"]
        case .settingsProvidersModelsCount:
            return [.spanish: "modelos", .french: "modèles", .german: "Modelle",
                    .chineseSimplified: "个模型", .japanese: "モデル", .korean: "개 모델", .portuguese: "modelos", .arabic: "نموذج"]
        case .settingsProvidersToolsEnabled:
            return [.spanish: "Herramientas activadas", .french: "Outils activés", .german: "Tools aktiviert",
                    .chineseSimplified: "工具已启用", .japanese: "ツール有効", .korean: "도구 활성화됨", .portuguese: "Ferramentas ativadas", .arabic: "الأدوات مفعّلة"]
        case .settingsProvidersACPEnabled:
            return [.spanish: "ACP activado", .french: "ACP activé", .german: "ACP aktiviert",
                    .chineseSimplified: "ACP 已启用", .japanese: "ACP 有効", .korean: "ACP 활성화됨", .portuguese: "ACP ativado", .arabic: "ACP مفعّل"]
        case .settingsProvidersRemove:
            return [.spanish: "Eliminar proveedor", .french: "Supprimer le fournisseur", .german: "Anbieter entfernen",
                    .chineseSimplified: "移除提供商", .japanese: "プロバイダーを削除", .korean: "공급자 제거", .portuguese: "Remover provedor", .arabic: "إزالة الموفر"]
        // Common
        case .settingsConfirm:
            return [.spanish: "Confirmar", .french: "Confirmer", .german: "Bestätigen",
                    .chineseSimplified: "确认", .japanese: "確認", .korean: "확인", .portuguese: "Confirmar", .arabic: "تأكيد"]
        case .settingsCancel:
            return [.spanish: "Cancelar", .french: "Annuler", .german: "Abbrechen",
                    .chineseSimplified: "取消", .japanese: "キャンセル", .korean: "취소", .portuguese: "Cancelar", .arabic: "إلغاء"]
        case .settingsRemove:
            return [.spanish: "Eliminar", .french: "Supprimer", .german: "Entfernen",
                    .chineseSimplified: "移除", .japanese: "削除", .korean: "제거", .portuguese: "Remover", .arabic: "إزالة"]
        case .settingsDelete:
            return [.spanish: "Eliminar", .french: "Supprimer", .german: "Löschen",
                    .chineseSimplified: "删除", .japanese: "削除", .korean: "삭제", .portuguese: "Excluir", .arabic: "حذف"]
        case .settingsArchive:
            return [.spanish: "Archivar", .french: "Archiver", .german: "Archivieren",
                    .chineseSimplified: "归档", .japanese: "アーカイブ", .korean: "보관", .portuguese: "Arquivar", .arabic: "أرشفة"]
        case .settingsRestore:
            return [.spanish: "Restaurar", .french: "Restaurer", .german: "Wiederherstellen",
                    .chineseSimplified: "恢复", .japanese: "復元", .korean: "복원", .portuguese: "Restaurar", .arabic: "استعادة"]
        case .settingsFindNewPath:
            return [.spanish: "Buscar nueva ruta…", .french: "Trouver un nouveau chemin…", .german: "Neuen Pfad finden…",
                    .chineseSimplified: "寻找新路径…", .japanese: "新しいパスを探す…", .korean: "새 경로 찾기…", .portuguese: "Encontrar novo caminho…", .arabic: "البحث عن مسار جديد…"]
        case .settingsExportBackup:
            return [.spanish: "Exportar copia de seguridad", .french: "Exporter la sauvegarde", .german: "Backup exportieren",
                    .chineseSimplified: "导出备份", .japanese: "バックアップをエクスポート", .korean: "백업 내보내기", .portuguese: "Exportar backup", .arabic: "تصدير النسخ الاحتياطي"]
        case .settingsImportBackup:
            return [.spanish: "Importar copia de seguridad", .french: "Importer la sauvegarde", .german: "Backup importieren",
                    .chineseSimplified: "导入备份", .japanese: "バックアップをインポート", .korean: "백업 가져오기", .portuguese: "Importar backup", .arabic: "استيراد النسخ الاحتياطي"]
        case .settingsCompress:
            return [.spanish: "Comprimir", .french: "Compresser", .german: "Komprimieren",
                    .chineseSimplified: "压缩", .japanese: "圧縮", .korean: "압축", .portuguese: "Comprimir", .arabic: "ضغط"]
        case .settingsArchiveNow:
            return [.spanish: "Archivar ahora", .french: "Archiver maintenant", .german: "Jetzt archivieren",
                    .chineseSimplified: "立即归档", .japanese: "今すぐアーカイブ", .korean: "지금 보관", .portuguese: "Arquivar agora", .arabic: "أرشفة الآن"]
        case .settingsDeleteOlderThan:
            return [.spanish: "Eliminar chats más antiguos que:", .french: "Supprimer les discussions plus anciennes que:", .german: "Chats älter als löschen:",
                    .chineseSimplified: "删除早于以下时间的聊天：", .japanese: "以下より古いチャットを削除：", .korean: "다음보다 오래된 채팅 삭제:", .portuguese: "Excluir chats mais antigos que:", .arabic: "حذف المحادثات الأقدم من:"]
        case .settingsTypeNameToConfirm:
            return [.spanish: "Escribe \"%@\" para confirmar", .french: "Tapez \"%@\" pour confirmer", .german: "Tippen Sie \"%@\" zum Bestätigen",
                    .chineseSimplified: "输入 \"%@\" 确认", .japanese: "\"%@\" と入力して確認", .korean: "\"%@\" 를 입력해 확인", .portuguese: "Digite \"%@\" para confirmar", .arabic: "اكتب \"%@\" للتأكيد"]
        case .settingsDeleteProjectDescription:
            return [.spanish: "Esto elimina \"%@\" de forma permanente. No se puede deshacer.", .french: "Cela supprime \"%@\" définitivement. Impossible d'annuler.", .german: "Dies löscht \"%@\" endgültig. Nicht rückgängig zu machen.",
                    .chineseSimplified: "这将永久删除 \"%@\"。无法撤销。", .japanese: "これは \"%@\" を永久に削除します。元に戻せません。", .korean: "이 작업은 \"%@\" 를 영구적으로 삭제합니다. 되돌릴 수 없습니다.", .portuguese: "Isso exclui \"%@\" permanentemente. Não pode ser desfeito.", .arabic: "سيحذف هذا \"%@\" بشكل دائم. لا يمكن التراجع."]
        case .settingsStorageQuotaExceeded:
            return [.spanish: "Cuota de almacenamiento superada", .french: "Quota de stockage dépassé", .german: "Speicherkontingent überschritten",
                    .chineseSimplified: "存储配额超限", .japanese: "ストレージ容量超過", .korean: "스토리지 할당량 초과", .portuguese: "Cota de armazenamento excedida", .arabic: "تم تجاوز حصة التخزين"]
        case .settingsStorageQuotaDescription:
            return [.spanish: "Las bases de datos de todos los proyectos usan %@, por encima del umbral del %@. Archivar proyectos inactivos liberaría %@.", .french: "Les bases de données de tous les projets utilisent %@, au-dessus du seuil de %@. L'archivage des projets inactifs libérerait %@.", .german: "Alle Projektdatenbanken verwenden %@, über dem Schwellenwert von %@. Das Archivieren inaktiver Projekte würde %@ freigeben.",
                    .chineseSimplified: "所有项目数据库使用 %@，超过 %@ 阈值。归档非活动项目可释放 %@。", .japanese: "すべてのプロジェクトデータベースが %@ を使用し、閾値 %@ を超えています。非アクティブなプロジェクトをアーカイブすると %@ が解放されます。", .korean: "모든 프로젝트 데이터베이스가 %@ 를 사용하며, 임계값 %@ 을 초과합니다. 비활성 프로젝트 아카이브로 %@ 를 확보할 수 있습니다.", .portuguese: "Bancos de dados de todos os projetos usam %@, acima do limite de %@. Arquivar projetos inativos liberaria %@.", .arabic: "تستخدم قواعد بيانات جميع المشاريع %@، فوق الحد %@. أرشفة المشاريع غير النشطة ستحرر %@."]
        case .settingsStorageQuotaArchiveInactive:
            return [.spanish: "Archivar inactivos", .french: "Archiver les inactifs", .german: "Inaktive archivieren",
                    .chineseSimplified: "归档非活动", .japanese: "非アクティブをアーカイブ", .korean: "비활성 아카이브", .portuguese: "Arquivar inativos", .arabic: "أرشفة غير النشط"]
        case .settingsNoProjectsRegistered:
            return [.spanish: "No hay proyectos registrados aún.", .french: "Aucun projet n'est encore enregistré.", .german: "Noch keine Projekte registriert.",
                    .chineseSimplified: "暂无注册项目。", .japanese: "登録されたプロジェクトがまだありません。", .korean: "아직 등록된 프로젝트가 없습니다.", .portuguese: "Nenhum projeto registrado ainda.", .arabic: "لا توجد مشاريع مسجلة بعد."]
        case .settingsActive:
            return [.spanish: "Activo", .french: "Actif", .german: "Aktiv",
                    .chineseSimplified: "活跃", .japanese: "アクティブ", .korean: "활성", .portuguese: "Ativo", .arabic: "نشط"]
        case .settingsArchived:
            return [.spanish: "Archivado", .french: "Archivé", .german: "Archiviert",
                    .chineseSimplified: "已归档", .japanese: "アーカイブ済み", .korean: "보관됨", .portuguese: "Arquivado", .arabic: "مؤرشف"]
        case .settingsOrphaned:
            return [.spanish: "Huérfano (ruta faltante)", .french: "Orphelin (chemin manquant)", .german: "Verwaist (Pfad fehlt)",
                    .chineseSimplified: "孤立 (路径缺失)", .japanese: "孤立 (パスなし)", .korean: "고아 (경로 없음)", .portuguese: "Órfão (caminho ausente)", .arabic: "يتيم (مسار مفقود)"]
        case .settingsAutoArchiveDescription:
            return [.spanish: "Los chats inactivos se archivan automáticamente tras el período seleccionado para ahorrar espacio. Se cargan a petición y se desarchivan al enviar un nuevo mensaje.", .french: "Les discussions inactives sont automatiquement archivées après la période sélectionnée pour économiser de l'espace. Elles sont chargées à la demande et désarchivées à l'envoi d'un nouveau message.", .german: "Inaktive Chats werden nach dem gewählten Zeitraum automatisch archiviert, um Speicherplatz zu sparen. Sie werden bei Bedarf geladen und beim Senden einer neuen Nachricht wieder entarchiviert.",
                    .chineseSimplified: "不活跃的聊天在选定时期后自动归档以节省空间。按需加载，发送新消息时自动解档。", .japanese: "非アクティブなチャットは選択した期間後に自動的にアーカイブされ、スペースを節約します。オンデマンドで読み込まれ、新しいメッセージを送信するとアーカイブ解除されます。", .korean: "비활성 채팅은 선택한 기간 후에 자동으로 보관되어 공간을 절약합니다. 필요 시 로드되고 새 메시지를 보내면 보관이 해제됩니다.", .portuguese: "Chats inativos são arquivados automaticamente após o período selecionado para economizar espaço. São carregados sob demanda e desarquivados ao enviar uma nova mensagem.", .arabic: "يتم أرشفة المحادثات غير النشطة تلقائيًا بعد الفترة المحددة لتوفير المساحة. يتم تحميلها عند الطلب وإلغاء أرشفتها عند إرسال رسالة جديدة."]
        case .settingsArchiveAfter:
            return [.spanish: "Archivar después de:", .french: "Archiver après:", .german: "Archivieren nach:",
                    .chineseSimplified: "归档时间：", .japanese: "アーカイブ期間：", .korean: "보관 기간:", .portuguese: "Arquivar após:", .arabic: "أرشفة بعد:"]
        case .settingsCleanupTitle:
            return [.spanish: "Limpieza", .french: "Nettoyage", .german: "Bereinigung",
                    .chineseSimplified: "清理", .japanese: "クリーンアップ", .korean: "정리", .portuguese: "Limpeza", .arabic: "تنظيف"]
        case .settingsCleanupDeleteChatsOlderThan:
            return [.spanish: "Eliminar chats más antiguos que:", .french: "Supprimer les discussions plus anciennes que:", .german: "Chats älter als löschen:",
                    .chineseSimplified: "删除早于以下时间的聊天：", .japanese: "以下より古いチャットを削除：", .korean: "다음보다 오래된 채팅 삭제:", .portuguese: "Excluir chats mais antigos que:", .arabic: "حذف المحادثات الأقدم من:"]
        case .settingsDeleteButton:
            return [.spanish: "Eliminar", .french: "Supprimer", .german: "Löschen",
                    .chineseSimplified: "删除", .japanese: "削除", .korean: "삭제", .portuguese: "Excluir", .arabic: "حذف"]
        case .settingsDeleteAllArchivedChats:
            return [.spanish: "Eliminar todos los chats archivados", .french: "Supprimer toutes les discussions archivées", .german: "Alle archivierten Chats löschen",
                    .chineseSimplified: "删除所有归档聊天", .japanese: "すべてのアーカイブ済みチャットを削除", .korean: "모든 보관된 채팅 삭제", .portuguese: "Excluir todos os chats arquivados", .arabic: "حذف جميع المحادثات المؤرشفة"]
        case .settingsCompressDatabase:
            return [.spanish: "Comprimir base de datos (VACUUM)", .french: "Compresser la base de données (VACUUM)", .german: "Datenbank komprimieren (VACUUM)",
                    .chineseSimplified: "压缩数据库 (VACUUM)", .japanese: "データベースを圧縮 (VACUUM)", .korean: "데이터베이스 압축 (VACUUM)", .portuguese: "Comprimir banco de dados (VACUUM)", .arabic: "ضغط قاعدة البيانات (VACUUM)"]
        case .settingsResetStorageTitle:
            return [.spanish: "Restablecer almacenamiento", .french: "Réinitialiser le stockage", .german: "Speicher zurücksetzen",
                    .chineseSimplified: "重置存储", .japanese: "ストレージをリセット", .korean: "스토리지 초기화", .portuguese: "Redefinir armazenamento", .arabic: "إعادة تعيين التخزين"]
        case .settingsResetAppCache:
            return [.spanish: "Limpiar caché de la app", .french: "Vider le cache de l'app", .german: "App-Cache leeren",
                    .chineseSimplified: "清理应用缓存", .japanese: "アプリのキャッシュをクリア", .korean: "앱 캐시 지우기", .portuguese: "Limpar cache do app", .arabic: "مسح ذاكرة التطبيق المؤقتة"]
        case .settingsClearAppCache:
            return [.spanish: "Limpiar caché de la app", .french: "Vider le cache de l'app", .german: "App-Cache leeren",
                    .chineseSimplified: "清理应用缓存", .japanese: "アプリのキャッシュをクリア", .korean: "앱 캐시 지우기", .portuguese: "Limpar cache do app", .arabic: "مسح ذاكرة التطبيق المؤقتة"]
        case .settingsArchiveInactive:
            return [.spanish: "Archivar inactivos", .french: "Archiver les inactifs", .german: "Inaktive archivieren",
                    .chineseSimplified: "归档非活动", .japanese: "非アクティブをアーカイブ", .korean: "비활성 아카이브", .portuguese: "Arquivar inativos", .arabic: "أرشفة غير النشط"]
        case .terminalTab:
            return [.spanish: "Terminal", .french: "Terminal", .german: "Terminal",
                    .chineseSimplified: "终端", .japanese: "ターミナル", .korean: "터미널", .portuguese: "Terminal", .arabic: "الطرفية"]
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
        case .settingsTabSkills: return ("Skills", "Навыки")
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
        case .settingsStorageTitle: return ("Storage  Title", "")
        case .settingsActive: return ("Active", "")
        case .settingsArchive: return ("Archive", "")
        case .settingsArchiveAfter: return ("ArchiveAfter", "")
        case .settingsArchiveInactive: return ("ArchiveInactive", "")
        case .settingsArchiveNow: return ("ArchiveNow", "")
        case .settingsArchived: return ("Archived", "")
        case .settingsAutoArchiveDescription: return ("AutoArchive Description", "")
        case .settingsCancel: return ("Cancel", "")
        case .settingsCleanupDeleteChatsOlderThan: return ("CleanupDeleteChatsOlderThan", "")
        case .settingsCleanupTitle: return ("Cleanup Title", "")
        case .settingsClearAppCache: return ("ClearAppCache", "")
        case .settingsCodeFontSizeDescription: return ("CodeFontSize Description", "")
        case .settingsCodeFontSizeTitle: return ("CodeFontSize Title", "")
        case .settingsCodePreviewTitle: return ("CodePreview Title", "")
        case .settingsCommandsDescription: return ("Commands Description", "")
        case .settingsCommandsTitle: return ("Commands Title", "")
        case .settingsCompress: return ("Compress", "")
        case .settingsCompressDatabase: return ("CompressDatabase", "")
        case .settingsConfirm: return ("Confirm", "")
        case .settingsDarkCodeThemeDescription: return ("DarkCodeTheme Description", "")
        case .settingsDarkCodeThemeTitle: return ("DarkCodeTheme Title", "")
        case .settingsDelete: return ("Delete", "")
        case .settingsDeleteAllArchivedChats: return ("DeleteAllArchivedChats", "")
        case .settingsDeleteButton: return ("Delete Button", "")
        case .settingsDeleteOlderThan: return ("DeleteOlderThan", "")
        case .settingsDeleteProjectDescription: return ("DeleteProject Description", "")
        case .settingsDisabled: return ("Disabled", "")
        case .settingsEnabled: return ("Enabled", "")
        case .settingsExportBackup: return ("ExportBackup", "")
        case .settingsFindNewPath: return ("FindNewPath", "")
        case .settingsImportBackup: return ("ImportBackup", "")
        case .settingsIndexNewFoldersDescription: return ("IndexNewFolders Description", "")
        case .settingsIndexNewFoldersTitle: return ("IndexNewFolders Title", "")
        case .settingsIndexRepositoriesDescription: return ("IndexRepositories Description", "")
        case .settingsIndexRepositoriesTitle: return ("IndexRepositories Title", "")
        case .settingsIndexingCodebaseTitle: return ("IndexingCodebase Title", "")
        case .settingsIndexingTitle: return ("Indexing Title", "")
        case .settingsLightCodeThemeDescription: return ("LightCodeTheme Description", "")
        case .settingsLightCodeThemeTitle: return ("LightCodeTheme Title", "")
        case .settingsLocalProvidersAdd: return ("LocalProvidersAdd", "")
        case .settingsLocalProvidersAdded: return ("LocalProvidersAdded", "")
        case .settingsLocalProvidersAddressPlaceholder: return ("LocalProvidersAddress", "")
        case .settingsLocalProvidersAutoDetect: return ("LocalProvidersAutoDetect", "")
        case .settingsLocalProvidersDescription: return ("LocalProviders Description", "")
        case .settingsLocalProvidersDetecting: return ("LocalProvidersDetecting", "")
        case .settingsLocalProvidersDisabled: return ("LocalProvidersDisabled", "")
        case .settingsLocalProvidersEnabled: return ("LocalProvidersEnabled", "")
        case .settingsLocalProvidersTitle: return ("LocalProviders Title", "")
        case .settingsMCPServersDescription: return ("MCPServers Description", "")
        case .settingsMCPServersTitle: return ("MCPServers Title", "")
        case .settingsModelSettingsDescription: return ("ModelSettings Description", "")
        case .settingsModelSettingsTitle: return ("ModelSettings Title", "")
        case .settingsNoMCPServersConfigured: return ("NoMCPServersConfigured", "")
        case .settingsNoMCPServersConfiguredSubtitle: return ("NoMCPServersConfigured Subtitle", "")
        case .settingsNoPluginsInstalled: return ("NoPluginsInstalled", "")
        case .settingsNoPluginsInstalledSubtitle: return ("NoPluginsInstalled Subtitle", "")
        case .settingsNoProjectsRegistered: return ("NoProjectsRegistered", "")
        case .settingsNoSkillsInstalled: return ("NoSkillsInstalled", "")
        case .settingsNoSkillsInstalledSubtitle: return ("NoSkillsInstalled Subtitle", "")
        case .settingsNoUserCommands: return ("NoUserCommands", "")
        case .settingsNoUserCommandsSubtitle: return ("NoUserCommands Subtitle", "")
        case .settingsOrphaned: return ("Orphaned", "")
        case .settingsPluginsDescription: return ("Plugins Description", "")
        case .settingsPluginsTitle: return ("Plugins Title", "")
        case .settingsProvidersACPEnabled: return ("ProvidersACPEnabled", "")
        case .settingsProvidersAdd: return ("ProvidersAdd", "")
        case .settingsProvidersDescription: return ("Providers Description", "")
        case .settingsProvidersModelsCount: return ("ProvidersModelsCount", "")
        case .settingsProvidersNoProviders: return ("ProvidersNoProviders", "")
        case .settingsProvidersRemove: return ("ProvidersRemove", "")
        case .settingsProvidersSearchPlaceholder: return ("ProvidersSearch", "")
        case .settingsProvidersStatsModels: return ("ProvidersStatsModels", "")
        case .settingsProvidersStatsProviders: return ("ProvidersStatsProviders", "")
        case .settingsProvidersTitle: return ("Providers Title", "")
        case .settingsProvidersToolsEnabled: return ("ProvidersToolsEnabled", "")
        case .settingsRemove: return ("Remove", "")
        case .settingsResetAppCache: return ("ResetAppCache", "")
        case .settingsResetStorageTitle: return ("ResetStorage Title", "")
        case .settingsRestore: return ("Restore", "")
        case .settingsSearchCommandsPlaceholder: return ("SearchCommands", "")
        case .settingsSearchMCPServersPlaceholder: return ("SearchMCPServers", "")
        case .settingsSearchPluginsPlaceholder: return ("SearchPlugins", "")
        case .settingsSearchSkillsPlaceholder: return ("SearchSkills", "")
        case .settingsShowLineNumbersDescription: return ("ShowLineNumbers Description", "")
        case .settingsShowLineNumbersTitle: return ("ShowLineNumbers Title", "")
        case .settingsSkillsDescription: return ("Skills Description", "")
        case .settingsSkillsTitle: return ("Skills Title", "")
        case .settingsStorageQuotaArchiveInactive: return ("StorageQuotaArchiveInactive", "")
        case .settingsStorageQuotaDescription: return ("StorageQuota Description", "")
        case .settingsStorageQuotaExceeded: return ("StorageQuotaExceeded", "")
        case .settingsTypeNameToConfirm: return ("TypeNameTo Confirm", "")
        case .settingsUsageActiveDays: return ("UsageActiveDays", "")
        case .settingsUsageByModel: return ("UsageByModel", "")
        case .settingsUsageDatabaseSize: return ("UsageDatabaseSize", "")
        case .settingsUsageFavoriteModel: return ("UsageFavoriteModel", "")
        case .settingsUsageFavoriteModelSubtitle: return ("UsageFavoriteModel Subtitle", "")
        case .settingsUsageMessages: return ("UsageMessages", "")
        case .settingsUsageNoData: return ("UsageNoData", "")
        case .settingsUsageSubtitle: return ("Usage Subtitle", "")
        case .settingsUsageTimeRange: return ("UsageTimeRange", "")
        case .settingsUsageTitle: return ("Usage Title", "")
        case .settingsUsageTotalCost: return ("UsageTotalCost", "")
        case .settingsUsageTotalTokens: return ("UsageTotalTokens", "")
        case .settingsWrapLongLinesDescription: return ("WrapLongLines Description", "")
        case .settingsWrapLongLinesTitle: return ("WrapLongLines Title", "")
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
