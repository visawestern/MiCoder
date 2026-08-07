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
    case loc180Days
    case locActiveChats
    case locActiveDays
    case locAdd
    case locAddFilesMicodercommands
    case locAddProvider
    case locAddProvider1
    case locAdjustTheDefaultFontSizeUsedCodePreviews
    case locApiKey
    case locAppUsage
    case locArchiveAfter
    case locArchived
    case locArchivedProjects
    case locArchivedProjects1
    case locAutoarchive
    case locAutomaticallyIndexAnyNewFoldersWithFewerThan500
    case locAutomaticallyIndexRepositoriesSpeedGrepSearches
    case locBack
    case locBaseUrl
    case locBrowseTheLibraryAndInstallMcpServersOneClickCon
    case locBrowseTheLibraryAndInstallSkillsOneClickManageL
    case locCannotPreviewImage
    case locChanges
    case locChanges1
    case locCleanup
    case locClearAll
    case locClose
    case locCodeFontSize
    case locCodePreview
    case locCodebase
    case locCommands
    case locConfiguration
    case locConfigureModelProvidersAndManageAvailableModels
    case locConfirmAndAdd
    case locConnectLocalAgentInstanceAnotherHost
    case locConnectTheLocalAgentAddCustomProvider
    case locConnectTheLocalAgentAddCustomProviderGetStarted
    case locCopyAll
    case locCreate
    case locCreateProject
    case locCreatePullRequest
    case locCustom
    case locCustomModels
    case locDarkCodeTheme
    case locDatabase
    case locDatabaseSize
    case locDays
    case locDays1
    case locDays2
    case locDays3
    case locDays4
    case locDefault
    case locDeleteChatsOlderThan
    case locDescriptionOptional
    case locDetails
    case locDisableForLocalModelsProvidersThatDontNeedAuthe
    case locDisplayLineNumbersCodePreviews
    case locEdit
    case locEnableAgentCoderProtocol
    case locEnableAgentCoderProtocolForAutonomousCodingTask
    case locEnableDisableInstalledPluginsPluginsBundleSkill
    case locEnableFunctiontoolCallingSupport
    case locEnableFunctiontoolCallingSupportForThisProvider
    case locEscClose
    case locExistingChromeCookies
    case locFavoriteModel
    case locFolder
    case locHttpProxy
    case locImagePreview
    case locInactiveChatsAreAutomaticallyArchivedAfterTheSe
    case locIndexNewFolders
    case locIndexRepositoriesForInstantGrepBeta
    case locIndexing
    case locKeep
    case locLibrary
    case locLightCodeTheme
    case locLoadingOlderMessages
    case locLocalProviders
    case locManageCustomModelProvidersAndViewServerconnecte
    case locManageMicoderAgentCommandFilesCommandsCanInvoke
    case locManagedBrowser
    case locMcpServers
    case locMessages
    case locMicoder
    case locModel
    case locModelDetails
    case locModelEffortAreChosenTheChatInputAfterConnecting
    case locModelSettings
    case locModels
    case locModels1
    case locModelsForThisProvider
    case locModelsLoaded
    case locName
    case locNewProject
    case locNext
    case locNotifications
    case locNotifications1
    case locNow
    case locOpenFolder
    case locOpenFullStoragePanel
    case locOrphanedPathMissing
    case locOverview
    case locParametersAvailable
    case locPerProject
    case locPickProviderTheLeftViewItsConnectionAndSettings
    case locPickServerFromTheLibraryAboveAndTapInstall
    case locPickSkillFromTheLibraryAboveAndTapInstall
    case locPlugins
    case locPluginsLiveUnderMicoderplugins
    case locProjectName
    case locProjects
    case locProjectsRegisteredYet
    case locProviderSelected
    case locProviderType
    case locProviders
    case locProvidersConfigured
    case locProvidersModels
    case locProvidersYet
    case locRemoteConnection
    case locRemove
    case locRetry
    case locRouteModelMcpCommandtoolAndAppRendererEgressTra
    case locRunModelsLocallyViaOllamaOpencodeMicoderCliserv
    case locSearch
    case locSelectProviderFirst
    case locShowLineNumbers
    case locSkills
    case locSnapshots
    case locStorageDatabase
    case locStorageQuotaExceeded
    case locSwitchPlanAgent
    case locSystemPrompt
    case locTaskCompletionsAndSystemAlertsWillAppearHere
    case locTasksYet
    case locTestConnection
    case locThemeUsedForCodeBlocksWhileTheInterfaceDarkMode
    case locThemeUsedForCodeBlocksWhileTheInterfaceLightMod
    case locThinking
    case locThisWillPermanentlyDeleteAllArchivedChatsAndThe
    case locTimeRange
    case locTitle
    case locToolsUnavailableForCurrentModel
    case locToolsUnavailableForTheCurrentModelProvider
    case locToolsUnavailableForThisModel
    case locTotal
    case locTotalCost
    case locTotalTokens
    case locTransmit
    case locUrl
    case locUsage
    case locUsage1
    case locUsageDataForTheSelectedPeriod
    case locUseFreeWebModelsKimiQwenChatgptThroughControlle
    case locWebProvidersBrowser
    case locWrapLongContentInsideThePreviewAreaAutomaticall
    case locWrapLongLines
    case locYear
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
        "locYear": ["en": "1 year", "ru": "1 year", "es": "1 año", "fr": "1 an", "de": "1 Jahr", "zh": "1 年", "ja": "1年", "ko": "1년", "pt": "1 ano"],
        "locDays": ["en": "14 days", "ru": "14 days", "es": "14 días", "fr": "14 jours", "de": "14 Tage", "zh": "14 天", "ja": "14日", "ko": "14일", "pt": "14 dias", "ar": "14 يومًا"],
        "loc180Days": ["en": "180 days", "ru": "180 days", "es": "180 días", "fr": "180 jours", "de": "180 Tage", "zh": "180 天", "ja": "180日", "ko": "180일", "pt": "180 dias", "ar": "180 يومًا"],
        "locDays1": ["en": "3 days", "ru": "3 days", "es": "3 días", "fr": "3 jours", "de": "3 Tage", "zh": "3 天", "ja": "3日", "ko": "3일", "pt": "3 dias", "ar": "3 أيام"],
        "locDays2": ["en": "30 days", "ru": "30 days", "es": "30 días", "fr": "30 jours", "de": "30 Tage", "zh": "30 天", "ja": "30日", "ko": "30일", "pt": "30 dias", "ar": "30 يومًا"],
        "locDays3": ["en": "7 days", "ru": "7 days", "es": "7 días", "fr": "7 jours", "de": "7 Tage", "zh": "7 天", "ja": "7日", "ko": "7일", "pt": "7 dias", "ar": "7 أيام"],
        "locDays4": ["en": "90 days", "ru": "90 days", "es": "90 días", "fr": "90 jours", "de": "90 Tage", "zh": "90 天", "ja": "90日", "ko": "90일", "pt": "90 dias", "ar": "90 يومًا"],
        "locApiKey": ["en": "API Key", "ru": "API Key", "es": "Clave API", "fr": "Clé API", "de": "API-Schlüssel", "zh": "API 密钥", "ja": "APIキー", "ko": "API 키", "pt": "Chave API", "ar": "مفتاح API"],
        "locActiveChats": ["en": "Active chats", "ru": "Active chats", "es": "Chats activos", "fr": "Conversations actives", "de": "Aktive Chats", "zh": "活跃聊天", "ja": "アクティブチャット", "ko": "활성 채팅", "pt": "Conversas ativas", "ar": "المحادثات النشطة"],
        "locActiveDays": ["en": "Active days", "ru": "Active days", "es": "Días activos", "fr": "Jours actifs", "de": "Aktive Tage", "zh": "活跃天数", "ja": "アクティブ日数", "ko": "활성 일수", "pt": "Dias ativos", "ar": "الأيام النشطة"],
        "locAdd": ["en": "Add", "ru": "Add", "es": "Agregar", "fr": "Ajouter", "de": "Hinzufügen", "zh": "添加", "ja": "追加", "ko": "추가", "pt": "Adicionar"],
        "locAddFilesMicodercommands": ["en": "Add .md files to ~/.micoder/commands", "ru": "Add .md files to ~/.micoder/commands", "fr": "Add .md files to ~/.micoder/commands", "zh": "Add .md files to ~/.micoder/commands", "ja": "Add .md files to ~/.micoder/commands", "ko": "Add .md files to ~/.micoder/commands", "pt": "Add .md files to ~/.micoder/commands", "ar": "Add .md files to ~/.micoder/commands"],
        "locAddProvider": ["en": "Add Provider", "ru": "Add Provider", "es": "Agregar proveedor", "fr": "Add Provider", "zh": "Add Provider", "ja": "Add Provider", "ko": "Add Provider", "pt": "Add Provider"],
        "locAddProvider1": ["en": "Add provider", "ru": "Add provider", "es": "Agregar proveedor", "fr": "Add provider", "zh": "Add provider", "ja": "Add provider", "ko": "Add provider", "pt": "Add provider"],
        "locAdjustTheDefaultFontSizeUsedCodePreviews": ["en": "Adjust the default font size used by code previews.", "ru": "Adjust the default font size used by code previews.", "es": "Adjust the default font size used by code previews.", "fr": "Adjust the default font size used by code previews.", "zh": "Adjust the default font size used by code previews.", "ja": "Adjust the default font size used by code previews.", "ko": "Adjust the default font size used by code previews.", "pt": "Adjust the default font size used by code previews.", "ar": "Adjust the default font size used by code previews."],
        "locAppUsage": ["en": "App usage", "ru": "App usage", "es": "App usage", "fr": "App usage", "de": "App usage", "zh": "App usage", "ja": "App usage", "ko": "App usage", "pt": "App usage", "ar": "App usage"],
        "locArchiveAfter": ["en": "Archive after:", "ru": "Archive after:", "es": "Archive after:", "fr": "Archive after:", "de": "Archive after:", "zh": "Archive after:", "ja": "Archive after:", "ko": "Archive after:", "pt": "Archive after:", "ar": "Archive after:"],
        "locArchived": ["en": "Archived", "ru": "Archived", "es": "Archivado", "fr": "Archivé", "de": "Archiviert", "zh": "已归档", "ja": "アーカイブ済み", "ko": "보관됨", "pt": "Arquivado", "ar": "مؤرشف"],
        "locArchivedProjects": ["en": "Archived projects", "ru": "Archived projects", "es": "Proyectos archivados", "fr": "Archived projects", "de": "Archived projects", "zh": "Archived projects", "ja": "Archived projects", "ko": "Archived projects", "pt": "Archived projects"],
        "locAutoarchive": ["en": "Auto-archive", "ru": "Auto-archive", "es": "Autoarchivar", "fr": "Auto-archive", "de": "Auto-archive", "zh": "Auto-archive", "ja": "Auto-archive", "ko": "Auto-archive", "pt": "Auto-archive"],
        "locAutomaticallyIndexAnyNewFoldersWithFewerThan500": ["en": "Automatically index any new folders with fewer than 50,000 files.", "ru": "Automatically index any new folders with fewer than 50,000 files.", "fr": "Automatically index any new folders with fewer than 50,000 files.", "zh": "Automatically index any new folders with fewer than 50,000 files.", "ja": "Automatically index any new folders with fewer than 50,000 files.", "ko": "Automatically index any new folders with fewer than 50,000 files.", "pt": "Automatically index any new folders with fewer than 50,000 files.", "ar": "Automatically index any new folders with fewer than 50,000 files."],
        "locAutomaticallyIndexRepositoriesSpeedGrepSearches": ["en": "Automatically index repositories to speed up Grep searches. All data is stored locally.", "ru": "Automatically index repositories to speed up Grep searches. All data is stored locally.", "fr": "Automatically index repositories to speed up Grep searches. All data is stored locally.", "zh": "Automatically index repositories to speed up Grep searches. All data is stored locally.", "ja": "Automatically index repositories to speed up Grep searches. All data is stored locally.", "ko": "Automatically index repositories to speed up Grep searches. All data is stored locally.", "pt": "Automatically index repositories to speed up Grep searches. All data is stored locally."],
        "locBack": ["en": "Back", "ru": "Back", "es": "Atrás", "fr": "Retour", "de": "Zurück", "zh": "返回", "ja": "戻る", "ko": "뒤로", "pt": "Voltar"],
        "locBaseUrl": ["en": "Base URL", "ru": "Base URL", "es": "URL base", "fr": "URL de base", "zh": "基础 URL", "ja": "ベースURL", "ko": "기본 URL", "pt": "URL base", "ar": "عنوان URL الأساسي"],
        "locBrowseTheLibraryAndInstallMcpServersOneClickCon": ["en": "Browse the library and install MCP servers in one click. Configurations are saved to ~/.micoder/mcp.json.", "ru": "Browse the library and install MCP servers in one click. Configurations are saved to ~/.micoder/mcp.json."],
        "locBrowseTheLibraryAndInstallSkillsOneClickManageL": ["en": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.", "ru": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.", "es": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.", "fr": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.", "zh": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.", "ja": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.", "ko": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.", "pt": "Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills."],
        "locModel": ["en": "By model", "ru": "By model", "es": "By model", "fr": "By model", "zh": "By model", "ja": "By model", "ko": "By model", "pt": "By model", "ar": "By model"],
        "locCannotPreviewImage": ["en": "Cannot preview image", "ru": "Cannot preview image", "es": "Cannot preview image", "fr": "Cannot preview image", "de": "Cannot preview image", "zh": "Cannot preview image", "ja": "Cannot preview image", "ko": "Cannot preview image", "pt": "Cannot preview image", "ar": "Cannot preview image"],
        "locChanges": ["en": "Changes", "ru": "Changes", "fr": "Changes", "de": "Changes", "zh": "Changes", "ja": "Changes", "ko": "Changes", "pt": "Changes", "ar": "Changes"],
        "locCleanup": ["en": "Cleanup", "ru": "Cleanup", "es": "Limpieza", "fr": "Nettoyage", "de": "Bereinigung", "zh": "清理", "ja": "クリーンアップ", "ko": "정리", "pt": "Limpeza", "ar": "التنظيف"],
        "locClearAll": ["en": "Clear all", "ru": "Clear all", "es": "Clear all", "fr": "Clear all", "de": "Clear all", "zh": "Clear all", "ja": "Clear all", "ko": "Clear all", "pt": "Clear all"],
        "locClose": ["en": "Close", "ru": "Close", "es": "Cerrar", "fr": "Fermer", "de": "Schließen", "zh": "关闭", "ja": "閉じる", "ko": "닫기", "pt": "Fechar"],
        "locCodeFontSize": ["en": "Code font size", "ru": "Code font size", "es": "Code font size", "fr": "Code font size", "zh": "Code font size", "ja": "Code font size", "ko": "Code font size", "pt": "Code font size", "ar": "Code font size"],
        "locCodePreview": ["en": "Code preview", "ru": "Code preview", "es": "Vista previa de código", "fr": "Aperçu du code", "zh": "代码预览", "ja": "コードプレビュー", "ko": "코드 미리보기", "pt": "Pré-visualização de código", "ar": "معاينة الكود"],
        "locCodebase": ["en": "Codebase", "ru": "Codebase", "es": "Codebase", "fr": "Codebase", "zh": "Codebase", "ja": "Codebase", "ko": "Codebase", "pt": "Codebase", "ar": "Codebase"],
        "locCommands": ["en": "Commands", "ru": "Commands", "es": "Comandos", "fr": "Commandes", "zh": "命令", "ja": "コマンド", "ko": "명령", "pt": "Comandos", "ar": "الأوامر"],
        "locConfiguration": ["en": "Configuration", "ru": "Configuration", "es": "Configuration", "fr": "Configuration", "de": "Configuration", "zh": "Configuration", "ja": "Configuration", "ko": "Configuration", "pt": "Configuration", "ar": "Configuration"],
        "locConfigureModelProvidersAndManageAvailableModels": ["en": "Configure model providers and manage available models.", "ru": "Configure model providers and manage available models.", "es": "Configure model providers and manage available models.", "fr": "Configure model providers and manage available models.", "zh": "Configure model providers and manage available models.", "ja": "Configure model providers and manage available models.", "ko": "Configure model providers and manage available models.", "pt": "Configure model providers and manage available models.", "ar": "Configure model providers and manage available models."],
        "locConfirmAndAdd": ["en": "Confirm and add", "ru": "Confirm and add", "es": "Confirm and add", "fr": "Confirm and add", "de": "Confirm and add", "zh": "Confirm and add", "ja": "Confirm and add", "ko": "Confirm and add", "pt": "Confirm and add", "ar": "Confirm and add"],
        "locConnectTheLocalAgentAddCustomProvider": ["en": "Connect the local agent or add a custom provider", "ru": "Connect the local agent or add a custom provider", "es": "Connect the local agent or add a custom provider", "fr": "Connect the local agent or add a custom provider", "zh": "Connect the local agent or add a custom provider", "ja": "Connect the local agent or add a custom provider", "ko": "Connect the local agent or add a custom provider", "pt": "Connect the local agent or add a custom provider", "ar": "Connect the local agent or add a custom provider"],
        "locConnectTheLocalAgentAddCustomProviderGetStarted": ["en": "Connect the local agent or add a custom provider to get started.", "ru": "Connect the local agent or add a custom provider to get started.", "es": "Connect the local agent or add a custom provider to get started.", "fr": "Connect the local agent or add a custom provider to get started.", "zh": "Connect the local agent or add a custom provider to get started.", "ja": "Connect the local agent or add a custom provider to get started.", "ko": "Connect the local agent or add a custom provider to get started.", "pt": "Connect the local agent or add a custom provider to get started."],
        "locConnectLocalAgentInstanceAnotherHost": ["en": "Connect to a local agent instance on another host.", "ru": "Connect to a local agent instance on another host.", "es": "Connect to a local agent instance on another host.", "fr": "Connect to a local agent instance on another host.", "de": "Connect to a local agent instance on another host.", "zh": "Connect to a local agent instance on another host.", "ja": "Connect to a local agent instance on another host.", "ko": "Connect to a local agent instance on another host.", "pt": "Connect to a local agent instance on another host.", "ar": "Connect to a local agent instance on another host."],
        "locCopyAll": ["en": "Copy All", "ru": "Copy All", "es": "Copy All", "fr": "Copy All", "de": "Copy All", "zh": "Copy All", "ja": "Copy All", "ko": "Copy All", "pt": "Copy All", "ar": "Copy All"],
        "locCreate": ["en": "Create PR", "ru": "Create PR", "es": "Create PR", "fr": "Create PR", "de": "Create PR", "zh": "Create PR", "ja": "Create PR", "ko": "Create PR", "pt": "Create PR", "ar": "Create PR"],
        "locCreateProject": ["en": "Create Project", "ru": "Create Project", "es": "Create Project", "fr": "Create Project", "de": "Create Project", "zh": "Create Project", "ja": "Create Project", "ko": "Create Project", "pt": "Create Project", "ar": "Create Project"],
        "locCreatePullRequest": ["en": "Create Pull Request", "ru": "Create Pull Request", "fr": "Create Pull Request", "de": "Create Pull Request", "zh": "Create Pull Request", "ja": "Create Pull Request", "ko": "Create Pull Request", "pt": "Create Pull Request", "ar": "Create Pull Request"],
        "locCustom": ["en": "Custom", "ru": "Custom", "es": "Personalizado", "fr": "Personnalisé", "de": "Benutzerdefiniert", "zh": "自定义", "ja": "カスタム", "ko": "사용자 정의", "pt": "Personalizado", "ar": "مخصص"],
        "locCustomModels": ["en": "Custom models", "ru": "Custom models", "es": "Custom models", "fr": "Custom models", "zh": "Custom models", "ja": "Custom models", "ko": "Custom models", "pt": "Custom models", "ar": "Custom models"],
        "locDarkCodeTheme": ["en": "Dark code theme", "ru": "Dark code theme", "es": "Dark code theme", "fr": "Dark code theme", "zh": "Dark code theme", "ja": "Dark code theme", "ko": "Dark code theme", "pt": "Dark code theme"],
        "locDatabase": ["en": "Database", "ru": "Database", "es": "Base de datos", "fr": "Base de données", "zh": "数据库", "ja": "データベース", "ko": "데이터베이스", "pt": "Base de dados", "ar": "قاعدة البيانات"],
        "locDatabaseSize": ["en": "Database size", "ru": "Database size", "es": "Database size", "fr": "Database size", "de": "Database size", "zh": "Database size", "ja": "Database size", "ko": "Database size", "pt": "Database size", "ar": "Database size"],
        "locDeleteChatsOlderThan": ["en": "Delete chats older than:", "ru": "Delete chats older than:", "es": "Delete chats older than:", "fr": "Delete chats older than:", "zh": "Delete chats older than:", "ja": "Delete chats older than:", "ko": "Delete chats older than:", "pt": "Delete chats older than:", "ar": "Delete chats older than:"],
        "locDescriptionOptional": ["en": "Description (optional)", "ru": "Description (optional)", "fr": "Description (optional)", "de": "Description (optional)", "zh": "Description (optional)", "ja": "Description (optional)", "ko": "Description (optional)", "ar": "Description (optional)"],
        "locDetails": ["en": "Details", "ru": "Details", "es": "Detalles", "fr": "Détails", "de": "Details", "zh": "详情", "ja": "詳細", "ko": "세부 정보", "pt": "Detalhes", "ar": "التفاصيل"],
        "locDisableForLocalModelsProvidersThatDontNeedAuthe": ["en": "Disable for local models or providers that don't need authentication", "ru": "Disable for local models or providers that don't need authentication", "es": "Disable for local models or providers that don't need authentication", "fr": "Disable for local models or providers that don't need authentication", "zh": "Disable for local models or providers that don't need authentication", "ja": "Disable for local models or providers that don't need authentication", "ko": "Disable for local models or providers that don't need authentication", "pt": "Disable for local models or providers that don't need authentication", "ar": "Disable for local models or providers that don't need authentication"],
        "locDisplayLineNumbersCodePreviews": ["en": "Display line numbers in code previews.", "ru": "Display line numbers in code previews.", "es": "Display line numbers in code previews.", "fr": "Display line numbers in code previews.", "zh": "Display line numbers in code previews.", "ja": "Display line numbers in code previews.", "ko": "Display line numbers in code previews.", "pt": "Display line numbers in code previews.", "ar": "Display line numbers in code previews."],
        "locEdit": ["en": "Edit", "ru": "Edit", "es": "Editar", "fr": "Modifier", "de": "Bearbeiten", "zh": "编辑", "ja": "編集", "ko": "편집", "pt": "Editar"],
        "locEnableAgentCoderProtocol": ["en": "Enable Agent Coder Protocol", "ru": "Enable Agent Coder Protocol", "es": "Enable Agent Coder Protocol", "fr": "Enable Agent Coder Protocol", "zh": "Enable Agent Coder Protocol", "ja": "Enable Agent Coder Protocol", "ko": "Enable Agent Coder Protocol", "pt": "Enable Agent Coder Protocol", "ar": "Enable Agent Coder Protocol"],
        "locEnableAgentCoderProtocolForAutonomousCodingTask": ["en": "Enable Agent Coder Protocol for autonomous coding tasks", "ru": "Enable Agent Coder Protocol for autonomous coding tasks", "es": "Enable Agent Coder Protocol for autonomous coding tasks", "fr": "Enable Agent Coder Protocol for autonomous coding tasks", "zh": "Enable Agent Coder Protocol for autonomous coding tasks", "ja": "Enable Agent Coder Protocol for autonomous coding tasks", "ko": "Enable Agent Coder Protocol for autonomous coding tasks", "pt": "Enable Agent Coder Protocol for autonomous coding tasks", "ar": "Enable Agent Coder Protocol for autonomous coding tasks"],
        "locEnableFunctiontoolCallingSupport": ["en": "Enable function/tool calling support", "ru": "Enable function/tool calling support", "es": "Enable function/tool calling support", "fr": "Enable function/tool calling support", "de": "Enable function/tool calling support", "zh": "Enable function/tool calling support", "ja": "Enable function/tool calling support", "ko": "Enable function/tool calling support", "pt": "Enable function/tool calling support", "ar": "Enable function/tool calling support"],
        "locEnableFunctiontoolCallingSupportForThisProvider": ["en": "Enable function/tool calling support for this provider", "ru": "Enable function/tool calling support for this provider", "es": "Enable function/tool calling support for this provider", "fr": "Enable function/tool calling support for this provider", "zh": "Enable function/tool calling support for this provider", "ja": "Enable function/tool calling support for this provider", "ko": "Enable function/tool calling support for this provider", "pt": "Enable function/tool calling support for this provider", "ar": "Enable function/tool calling support for this provider"],
        "locEnableDisableInstalledPluginsPluginsBundleSkill": ["en": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "ru": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "es": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "fr": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "de": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "zh": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "ja": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "ko": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "pt": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.", "ar": "Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers."],
        "locEscClose": ["en": "Esc to close", "ru": "Esc to close", "es": "Esc to close", "fr": "Esc to close", "de": "Esc to close", "zh": "Esc to close", "ja": "Esc to close", "ko": "Esc to close", "pt": "Esc to close", "ar": "Esc to close"],
        "locExistingChromeCookies": ["en": "Existing Chrome (cookies)", "ru": "Existing Chrome (cookies)", "fr": "Existing Chrome (cookies)", "de": "Existing Chrome (cookies)", "zh": "Existing Chrome (cookies)", "ja": "Existing Chrome (cookies)", "ko": "Existing Chrome (cookies)", "pt": "Existing Chrome (cookies)", "ar": "Existing Chrome (cookies)"],
        "locFavoriteModel": ["en": "Favorite model", "ru": "Favorite model", "es": "Favorite model", "fr": "Favorite model", "zh": "Favorite model", "ja": "Favorite model", "ko": "Favorite model", "pt": "Favorite model", "ar": "Favorite model"],
        "locFolder": ["en": "Folder", "ru": "Folder", "es": "Carpeta", "fr": "Dossier", "zh": "文件夹", "ja": "フォルダー", "ko": "폴더", "pt": "Pasta"],
        "locHttpProxy": ["en": "HTTP Proxy", "ru": "HTTP Proxy", "es": "HTTP Proxy", "fr": "HTTP Proxy", "de": "HTTP Proxy", "zh": "HTTP Proxy", "ja": "HTTP Proxy", "ko": "HTTP Proxy", "pt": "HTTP Proxy", "ar": "HTTP Proxy"],
        "locImagePreview": ["en": "Image Preview", "ru": "Image Preview", "es": "Image Preview", "fr": "Image Preview", "de": "Image Preview", "zh": "Image Preview", "ja": "Image Preview", "ko": "Image Preview", "pt": "Image Preview", "ar": "Image Preview"],
        "locInactiveChatsAreAutomaticallyArchivedAfterTheSe": ["en": "Inactive chats are automatically archived after the selected period to save space. They are loaded on demand and unarchived when you send a new message.", "ru": "Inactive chats are automatically archived after the selected period to save space. They are loaded on demand and unarchived when you send a new message."],
        "locIndexNewFolders": ["en": "Index new folders", "ru": "Index new folders", "es": "Index new folders", "fr": "Index new folders", "zh": "Index new folders", "ja": "Index new folders", "ko": "Index new folders", "pt": "Index new folders", "ar": "Index new folders"],
        "locIndexRepositoriesForInstantGrepBeta": ["en": "Index repositories for instant grep (Beta)", "ru": "Index repositories for instant grep (Beta)", "fr": "Index repositories for instant grep (Beta)", "zh": "Index repositories for instant grep (Beta)", "ja": "Index repositories for instant grep (Beta)", "ko": "Index repositories for instant grep (Beta)", "pt": "Index repositories for instant grep (Beta)", "ar": "Index repositories for instant grep (Beta)"],
        "locIndexing": ["en": "Indexing", "ru": "Indexing", "es": "Indexación", "fr": "Indexation", "zh": "索引", "ja": "インデックス", "ko": "인덱싱", "pt": "Indexação", "ar": "الفهرسة"],
        "locKeep": ["en": "Keep", "ru": "Keep", "es": "Keep", "fr": "Keep", "de": "Keep", "zh": "Keep", "ja": "Keep", "ko": "Keep", "pt": "Keep", "ar": "Keep"],
        "locLibrary": ["en": "Library", "ru": "Library", "es": "Biblioteca", "fr": "Bibliothèque", "de": "Bibliothek", "zh": "库", "ja": "ライブラリ", "ko": "라이브러리", "pt": "Biblioteca"],
        "locLightCodeTheme": ["en": "Light code theme", "ru": "Light code theme", "es": "Light code theme", "fr": "Light code theme", "zh": "Light code theme", "ja": "Light code theme", "ko": "Light code theme", "pt": "Light code theme", "ar": "Light code theme"],
        "locLoadingOlderMessages": ["en": "Loading older messages...", "ru": "Loading older messages...", "fr": "Loading older messages...", "zh": "Loading older messages...", "ja": "Loading older messages...", "ko": "Loading older messages...", "pt": "Loading older messages...", "ar": "Loading older messages..."],
        "locLocalProviders": ["en": "Local providers", "ru": "Local providers", "es": "Local providers", "fr": "Local providers", "zh": "Local providers", "ja": "Local providers", "ko": "Local providers", "pt": "Local providers", "ar": "Local providers"],
        "locMcpServers": ["en": "MCP Servers", "ru": "MCP Servers", "es": "Servidores MCP", "fr": "Serveurs MCP", "de": "MCP-Server", "zh": "MCP 服务器", "ja": "MCPサーバー", "ko": "MCP 서버", "pt": "Servidores MCP", "ar": "خوادم MCP"],
        "locManageMicoderAgentCommandFilesCommandsCanInvoke": ["en": "Manage MiCoder Agent .md command files. Commands can be invoked with /command-name in chat.", "ru": "Manage MiCoder Agent .md command files. Commands can be invoked with /command-name in chat."],
        "locManageCustomModelProvidersAndViewServerconnecte": ["en": "Manage custom model providers and view server-connected providers.", "ru": "Manage custom model providers and view server-connected providers.", "es": "Manage custom model providers and view server-connected providers.", "fr": "Manage custom model providers and view server-connected providers.", "zh": "Manage custom model providers and view server-connected providers.", "ja": "Manage custom model providers and view server-connected providers.", "ko": "Manage custom model providers and view server-connected providers.", "pt": "Manage custom model providers and view server-connected providers.", "ar": "Manage custom model providers and view server-connected providers."],
        "locManagedBrowser": ["en": "Managed browser", "ru": "Managed browser", "es": "Managed browser", "fr": "Managed browser", "de": "Managed browser", "zh": "Managed browser", "ja": "Managed browser", "ko": "Managed browser", "pt": "Managed browser", "ar": "Managed browser"],
        "locMessages": ["en": "Messages", "ru": "Messages", "fr": "Messages", "de": "Nachrichten", "zh": "消息", "ja": "メッセージ", "ko": "메시지", "pt": "Mensagens", "ar": "الرسائل"],
        "locMicoder": ["en": "MiCoder", "ru": "MiCoder", "es": "MiCoder", "fr": "MiCoder", "zh": "MiCoder", "ja": "MiCoder", "ko": "MiCoder", "pt": "MiCoder", "ar": "MiCoder"],
        "locModelEffortAreChosenTheChatInputAfterConnecting": ["en": "Model & effort are chosen in the chat input after connecting.", "ru": "Model & effort are chosen in the chat input after connecting.", "es": "Model & effort are chosen in the chat input after connecting.", "fr": "Model & effort are chosen in the chat input after connecting.", "zh": "Model & effort are chosen in the chat input after connecting.", "ja": "Model & effort are chosen in the chat input after connecting.", "ko": "Model & effort are chosen in the chat input after connecting.", "pt": "Model & effort are chosen in the chat input after connecting."],
        "locModelDetails": ["en": "Model Details", "ru": "Model Details", "es": "Model Details", "fr": "Model Details", "zh": "Model Details", "ja": "Model Details", "ko": "Model Details", "pt": "Model Details", "ar": "Model Details"],
        "locModelSettings": ["en": "Model settings", "ru": "Model settings", "es": "Model settings", "fr": "Model settings", "zh": "Model settings", "ja": "Model settings", "ko": "Model settings", "pt": "Model settings", "ar": "Model settings"],
        "locModels": ["en": "Models", "ru": "Models", "es": "Modelos", "fr": "Modèles", "zh": "模型", "ja": "モデル", "ko": "모델", "pt": "Modelos", "ar": "النماذج"],
        "locModels1": ["en": "Models:", "ru": "Models:", "es": "Models:", "fr": "Models:", "zh": "Models:", "ja": "Models:", "ko": "Models:", "pt": "Models:", "ar": "Models:"],
        "locName": ["en": "Name", "ru": "Name", "es": "Nombre", "fr": "Nom", "de": "Name", "zh": "名称", "ja": "名前", "ko": "이름", "pt": "Nome", "ar": "الاسم"],
        "locNewProject": ["en": "New Project", "ru": "New Project", "es": "Nuevo proyecto", "fr": "Nouveau projet", "de": "Neues Projekt", "zh": "新建项目", "ja": "新規プロジェクト", "ko": "새 프로젝트", "pt": "Novo projeto", "ar": "مشروع جديد"],
        "locNext": ["en": "Next", "ru": "Next", "es": "Next", "fr": "Next", "de": "Next", "zh": "Next", "ja": "Next", "ko": "Next", "pt": "Next", "ar": "Next"],
        "locArchivedProjects1": ["en": "No archived projects", "ru": "No archived projects", "es": "No archived projects", "fr": "No archived projects", "de": "No archived projects", "zh": "No archived projects", "ja": "No archived projects", "ko": "No archived projects", "pt": "No archived projects"],
        "locChanges1": ["en": "No changes", "ru": "No changes", "fr": "No changes", "de": "No changes", "zh": "No changes", "ja": "No changes", "ko": "No changes", "pt": "No changes", "ar": "No changes"],
        "locModelsForThisProvider": ["en": "No models for this provider", "ru": "No models for this provider", "es": "No models for this provider", "fr": "No models for this provider", "zh": "No models for this provider", "ja": "No models for this provider", "ko": "No models for this provider", "pt": "No models for this provider", "ar": "No models for this provider"],
        "locModelsLoaded": ["en": "No models loaded", "ru": "No models loaded", "es": "No models loaded", "fr": "No models loaded", "zh": "No models loaded", "ja": "No models loaded", "ko": "No models loaded", "pt": "No models loaded", "ar": "No models loaded"],
        "locNotifications": ["en": "No notifications", "ru": "No notifications", "es": "No notifications", "fr": "No notifications", "de": "No notifications", "zh": "No notifications", "ja": "No notifications", "ko": "No notifications", "pt": "No notifications", "ar": "No notifications"],
        "locParametersAvailable": ["en": "No parameters available", "ru": "No parameters available", "es": "No parameters available", "fr": "No parameters available", "de": "No parameters available", "zh": "No parameters available", "ja": "No parameters available", "ko": "No parameters available", "pt": "No parameters available"],
        "locProjectsRegisteredYet": ["en": "No projects registered yet.", "ru": "No projects registered yet.", "es": "No projects registered yet.", "fr": "No projects registered yet.", "de": "No projects registered yet.", "zh": "No projects registered yet.", "ja": "No projects registered yet.", "ko": "No projects registered yet.", "pt": "No projects registered yet.", "ar": "No projects registered yet."],
        "locProviderSelected": ["en": "No provider selected", "ru": "No provider selected", "es": "No provider selected", "fr": "No provider selected", "zh": "No provider selected", "ja": "No provider selected", "ko": "No provider selected", "pt": "No provider selected", "ar": "No provider selected"],
        "locProvidersConfigured": ["en": "No providers configured", "ru": "No providers configured", "es": "No providers configured", "fr": "No providers configured", "zh": "No providers configured", "ja": "No providers configured", "ko": "No providers configured", "pt": "No providers configured", "ar": "No providers configured"],
        "locProvidersYet": ["en": "No providers yet", "ru": "No providers yet", "es": "No providers yet", "fr": "No providers yet", "zh": "No providers yet", "ja": "No providers yet", "ko": "No providers yet", "pt": "No providers yet", "ar": "No providers yet"],
        "locTasksYet": ["en": "No tasks yet", "ru": "No tasks yet", "es": "No tasks yet", "fr": "No tasks yet", "de": "No tasks yet", "zh": "No tasks yet", "ja": "No tasks yet", "ko": "No tasks yet", "pt": "No tasks yet", "ar": "No tasks yet"],
        "locUsageDataForTheSelectedPeriod": ["en": "No usage data for the selected period.", "ru": "No usage data for the selected period.", "es": "No usage data for the selected period.", "fr": "No usage data for the selected period.", "de": "No usage data for the selected period.", "zh": "No usage data for the selected period.", "ja": "No usage data for the selected period.", "ko": "No usage data for the selected period.", "pt": "No usage data for the selected period.", "ar": "No usage data for the selected period."],
        "locNotifications1": ["en": "Notifications", "ru": "Notifications", "es": "Notificaciones", "fr": "Notifications", "de": "Benachrichtigungen", "zh": "通知", "ja": "通知", "ko": "알림", "pt": "Notificações", "ar": "الإشعارات"],
        "locOpenFolder": ["en": "Open folder", "ru": "Open folder", "es": "Open folder", "fr": "Open folder", "zh": "Open folder", "ja": "Open folder", "ko": "Open folder", "pt": "Open folder", "ar": "Open folder"],
        "locOpenFullStoragePanel": ["en": "Open full storage panel", "ru": "Open full storage panel", "es": "Open full storage panel", "fr": "Open full storage panel", "de": "Open full storage panel", "zh": "Open full storage panel", "ja": "Open full storage panel", "ko": "Open full storage panel", "pt": "Open full storage panel", "ar": "Open full storage panel"],
        "locOrphanedPathMissing": ["en": "Orphaned (path missing)", "ru": "Orphaned (path missing)", "es": "Orphaned (path missing)", "fr": "Orphaned (path missing)", "de": "Orphaned (path missing)", "zh": "Orphaned (path missing)", "ja": "Orphaned (path missing)", "ko": "Orphaned (path missing)", "pt": "Orphaned (path missing)", "ar": "Orphaned (path missing)"],
        "locOverview": ["en": "Overview", "ru": "Overview", "es": "Vista general", "fr": "Aperçu", "de": "Übersicht", "zh": "概览", "ja": "概要", "ko": "개요", "pt": "Visão geral", "ar": "نظرة عامة"],
        "locPerProject": ["en": "Per project", "ru": "Per project", "es": "Per project", "fr": "Per project", "de": "Per project", "zh": "Per project", "ja": "Per project", "ko": "Per project", "pt": "Per project", "ar": "Per project"],
        "locPickProviderTheLeftViewItsConnectionAndSettings": ["en": "Pick a provider on the left to view its connection and settings.", "ru": "Pick a provider on the left to view its connection and settings.", "es": "Pick a provider on the left to view its connection and settings.", "fr": "Pick a provider on the left to view its connection and settings.", "zh": "Pick a provider on the left to view its connection and settings.", "ja": "Pick a provider on the left to view its connection and settings.", "ko": "Pick a provider on the left to view its connection and settings.", "pt": "Pick a provider on the left to view its connection and settings.", "ar": "Pick a provider on the left to view its connection and settings."],
        "locPickServerFromTheLibraryAboveAndTapInstall": ["en": "Pick a server from the library above and tap Install.", "ru": "Pick a server from the library above and tap Install.", "es": "Pick a server from the library above and tap Install.", "de": "Pick a server from the library above and tap Install.", "zh": "Pick a server from the library above and tap Install.", "ja": "Pick a server from the library above and tap Install.", "ko": "Pick a server from the library above and tap Install.", "pt": "Pick a server from the library above and tap Install."],
        "locPickSkillFromTheLibraryAboveAndTapInstall": ["en": "Pick a skill from the library above and tap Install.", "ru": "Pick a skill from the library above and tap Install.", "es": "Pick a skill from the library above and tap Install.", "de": "Pick a skill from the library above and tap Install.", "zh": "Pick a skill from the library above and tap Install.", "ja": "Pick a skill from the library above and tap Install.", "ko": "Pick a skill from the library above and tap Install.", "pt": "Pick a skill from the library above and tap Install."],
        "locPlugins": ["en": "Plugins", "ru": "Plugins", "es": "Plugins", "fr": "Plugins", "de": "Plugins", "zh": "插件", "ja": "プラグイン", "ko": "플러그인", "pt": "Plugins", "ar": "الإضافات"],
        "locPluginsLiveUnderMicoderplugins": ["en": "Plugins live under ~/.micoder/plugins", "ru": "Plugins live under ~/.micoder/plugins", "es": "Plugins live under ~/.micoder/plugins", "fr": "Plugins live under ~/.micoder/plugins", "zh": "Plugins live under ~/.micoder/plugins", "ja": "Plugins live under ~/.micoder/plugins", "ko": "Plugins live under ~/.micoder/plugins", "pt": "Plugins live under ~/.micoder/plugins", "ar": "Plugins live under ~/.micoder/plugins"],
        "locProjectName": ["en": "Project Name", "ru": "Project Name", "es": "Project Name", "fr": "Project Name", "de": "Project Name", "zh": "Project Name", "ja": "Project Name", "ko": "Project Name", "pt": "Project Name", "ar": "Project Name"],
        "locProjects": ["en": "Projects", "ru": "Projects", "es": "Projects", "fr": "Projects", "de": "Projects", "zh": "Projects", "ja": "Projects", "ko": "Projects", "pt": "Projects", "ar": "Projects"],
        "locProviderType": ["en": "Provider Type", "ru": "Provider Type", "es": "Provider Type", "fr": "Provider Type", "zh": "Provider Type", "ja": "Provider Type", "ko": "Provider Type", "pt": "Provider Type", "ar": "Provider Type"],
        "locProviders": ["en": "Providers", "ru": "Providers", "es": "Proveedores", "fr": "Fournisseurs", "zh": "提供商", "ja": "プロバイダー", "ko": "공급자", "pt": "Fornecedores", "ar": "المقدّمون"],
        "locProvidersModels": ["en": "Providers & models", "ru": "Providers & models", "es": "Providers & models", "fr": "Providers & models", "zh": "Providers & models", "ja": "Providers & models", "ko": "Providers & models", "pt": "Providers & models", "ar": "Providers & models"],
        "locRemoteConnection": ["en": "Remote connection", "ru": "Remote connection", "es": "Remote connection", "fr": "Remote connection", "de": "Remote connection", "zh": "Remote connection", "ja": "Remote connection", "ko": "Remote connection", "pt": "Remote connection", "ar": "Remote connection"],
        "locRemove": ["en": "Remove", "ru": "Remove", "es": "Eliminar", "fr": "Supprimer", "de": "Entfernen", "zh": "移除", "ja": "削除", "ko": "제거", "pt": "Remover"],
        "locRetry": ["en": "Retry", "ru": "Retry", "es": "Reintentar", "fr": "Réessayer", "de": "Erneut versuchen", "zh": "重试", "ja": "再試行", "ko": "다시 시도", "pt": "Tentar novamente"],
        "locRouteModelMcpCommandtoolAndAppRendererEgressTra": ["en": "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect.", "ru": "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect.", "fr": "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect.", "zh": "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect.", "ja": "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect.", "ko": "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect.", "pt": "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect."],
        "locRunModelsLocallyViaOllamaOpencodeMicoderCliserv": ["en": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.", "ru": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.", "fr": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.", "zh": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.", "ja": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.", "ko": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.", "pt": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.", "ar": "Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models."],
        "locSearch": ["en": "Search", "ru": "Search", "es": "Buscar", "fr": "Rechercher", "de": "Suchen", "zh": "搜索", "ja": "検索", "ko": "검색", "pt": "Pesquisar"],
        "locSelectProviderFirst": ["en": "Select a provider first", "ru": "Select a provider first", "es": "Select a provider first", "fr": "Select a provider first", "zh": "Select a provider first", "ja": "Select a provider first", "ko": "Select a provider first", "pt": "Select a provider first", "ar": "Select a provider first"],
        "locShowLineNumbers": ["en": "Show line numbers", "ru": "Show line numbers", "es": "Show line numbers", "fr": "Show line numbers", "de": "Show line numbers", "zh": "Show line numbers", "ja": "Show line numbers", "ko": "Show line numbers", "pt": "Show line numbers", "ar": "Show line numbers"],
        "locSkills": ["en": "Skills", "ru": "Skills", "es": "Habilidades", "fr": "Compétences", "zh": "技能", "ja": "スキル", "ko": "스킬", "pt": "Competências", "ar": "المهارات"],
        "locSnapshots": ["en": "Snapshots", "ru": "Snapshots", "es": "Snapshots", "fr": "Snapshots", "de": "Snapshots", "zh": "Snapshots", "ja": "Snapshots", "ko": "Snapshots", "pt": "Snapshots", "ar": "Snapshots"],
        "locStorageDatabase": ["en": "Storage & Database", "ru": "Storage & Database", "es": "Almacenamiento y base de datos", "fr": "Storage & Database", "zh": "Storage & Database", "ja": "Storage & Database", "ko": "Storage & Database", "pt": "Storage & Database", "ar": "Storage & Database"],
        "locStorageQuotaExceeded": ["en": "Storage quota exceeded", "ru": "Storage quota exceeded", "es": "Storage quota exceeded", "fr": "Storage quota exceeded", "zh": "Storage quota exceeded", "ja": "Storage quota exceeded", "ko": "Storage quota exceeded", "pt": "Storage quota exceeded", "ar": "Storage quota exceeded"],
        "locSwitchPlanAgent": ["en": "Switch to Plan agent", "ru": "Switch to Plan agent", "es": "Switch to Plan agent", "fr": "Switch to Plan agent", "de": "Switch to Plan agent", "zh": "Switch to Plan agent", "ja": "Switch to Plan agent", "ko": "Switch to Plan agent", "pt": "Switch to Plan agent", "ar": "Switch to Plan agent"],
        "locSystemPrompt": ["en": "System prompt", "ru": "System prompt", "es": "System prompt", "fr": "System prompt", "de": "System prompt", "zh": "System prompt", "ja": "System prompt", "ko": "System prompt", "ar": "System prompt"],
        "locTaskCompletionsAndSystemAlertsWillAppearHere": ["en": "Task completions and system alerts will appear here.", "ru": "Task completions and system alerts will appear here.", "es": "Task completions and system alerts will appear here.", "fr": "Task completions and system alerts will appear here.", "de": "Task completions and system alerts will appear here.", "zh": "Task completions and system alerts will appear here.", "ja": "Task completions and system alerts will appear here.", "ko": "Task completions and system alerts will appear here.", "pt": "Task completions and system alerts will appear here."],
        "locTestConnection": ["en": "Test Connection", "ru": "Test Connection", "fr": "Test Connection", "de": "Test Connection", "zh": "Test Connection", "ja": "Test Connection", "ko": "Test Connection", "pt": "Test Connection", "ar": "Test Connection"],
        "locThemeUsedForCodeBlocksWhileTheInterfaceDarkMode": ["en": "Theme used for code blocks while the interface is in dark mode.", "ru": "Theme used for code blocks while the interface is in dark mode.", "es": "Theme used for code blocks while the interface is in dark mode.", "fr": "Theme used for code blocks while the interface is in dark mode.", "zh": "Theme used for code blocks while the interface is in dark mode.", "ja": "Theme used for code blocks while the interface is in dark mode.", "ko": "Theme used for code blocks while the interface is in dark mode.", "pt": "Theme used for code blocks while the interface is in dark mode."],
        "locThemeUsedForCodeBlocksWhileTheInterfaceLightMod": ["en": "Theme used for code blocks while the interface is in light mode.", "ru": "Theme used for code blocks while the interface is in light mode.", "es": "Theme used for code blocks while the interface is in light mode.", "fr": "Theme used for code blocks while the interface is in light mode.", "zh": "Theme used for code blocks while the interface is in light mode.", "ja": "Theme used for code blocks while the interface is in light mode.", "ko": "Theme used for code blocks while the interface is in light mode.", "pt": "Theme used for code blocks while the interface is in light mode.", "ar": "Theme used for code blocks while the interface is in light mode."],
        "locThinking": ["en": "Thinking", "ru": "Thinking", "es": "Thinking", "fr": "Thinking", "de": "Thinking", "zh": "Thinking", "ja": "Thinking", "ko": "Thinking", "pt": "Thinking", "ar": "Thinking"],
        "locThisWillPermanentlyDeleteAllArchivedChatsAndThe": ["en": "This will permanently delete ALL archived chats and their messages. This action cannot be undone.", "ru": "This will permanently delete ALL archived chats and their messages. This action cannot be undone.", "fr": "This will permanently delete ALL archived chats and their messages. This action cannot be undone.", "zh": "This will permanently delete ALL archived chats and their messages. This action cannot be undone.", "ja": "This will permanently delete ALL archived chats and their messages. This action cannot be undone.", "ko": "This will permanently delete ALL archived chats and their messages. This action cannot be undone.", "pt": "This will permanently delete ALL archived chats and their messages. This action cannot be undone."],
        "locTimeRange": ["en": "Time range", "ru": "Time range", "es": "Time range", "fr": "Time range", "de": "Time range", "zh": "Time range", "ja": "Time range", "ko": "Time range", "pt": "Time range", "ar": "Time range"],
        "locTitle": ["en": "Title", "ru": "Title", "es": "Title", "fr": "Title", "de": "Title", "zh": "Title", "ja": "Title", "ko": "Title", "pt": "Title", "ar": "Title"],
        "locToolsUnavailableForCurrentModel": ["en": "Tools unavailable for current model", "ru": "Tools unavailable for current model", "es": "Tools unavailable for current model", "fr": "Tools unavailable for current model", "zh": "Tools unavailable for current model", "ja": "Tools unavailable for current model", "ko": "Tools unavailable for current model", "pt": "Tools unavailable for current model", "ar": "Tools unavailable for current model"],
        "locToolsUnavailableForTheCurrentModelProvider": ["en": "Tools unavailable for the current model or provider.", "ru": "Tools unavailable for the current model or provider.", "es": "Tools unavailable for the current model or provider.", "fr": "Tools unavailable for the current model or provider.", "zh": "Tools unavailable for the current model or provider.", "ja": "Tools unavailable for the current model or provider.", "ko": "Tools unavailable for the current model or provider.", "pt": "Tools unavailable for the current model or provider.", "ar": "Tools unavailable for the current model or provider."],
        "locToolsUnavailableForThisModel": ["en": "Tools unavailable for this model", "ru": "Tools unavailable for this model", "es": "Tools unavailable for this model", "fr": "Tools unavailable for this model", "zh": "Tools unavailable for this model", "ja": "Tools unavailable for this model", "ko": "Tools unavailable for this model", "pt": "Tools unavailable for this model", "ar": "Tools unavailable for this model"],
        "locTotal": ["en": "Total", "ru": "Total", "es": "Total", "fr": "Total", "de": "Gesamt", "zh": "总计", "ja": "合計", "ko": "총계", "pt": "Total", "ar": "الإجمالي"],
        "locTotalCost": ["en": "Total cost", "ru": "Total cost", "es": "Total cost", "fr": "Total cost", "de": "Total cost", "zh": "Total cost", "ja": "Total cost", "ko": "Total cost", "pt": "Total cost", "ar": "Total cost"],
        "locTotalTokens": ["en": "Total tokens", "ru": "Total tokens", "es": "Total tokens", "fr": "Total tokens", "de": "Total tokens", "zh": "Total tokens", "ja": "Total tokens", "ko": "Total tokens", "pt": "Total tokens", "ar": "Total tokens"],
        "locTransmit": ["en": "Transmit", "ru": "Transmit", "es": "Transmit", "fr": "Transmit", "de": "Transmit", "zh": "Transmit", "ja": "Transmit", "ko": "Transmit", "pt": "Transmit", "ar": "Transmit"],
        "locUrl": ["en": "URL:", "ru": "URL:", "es": "URL:", "fr": "URL:", "de": "URL:", "zh": "URL:", "ja": "URL:", "ko": "URL:", "pt": "URL:", "ar": "URL:"],
        "locUsage": ["en": "Usage", "ru": "Usage", "es": "Uso", "fr": "Utilisation", "de": "Nutzung", "zh": "使用情况", "ja": "使用状況", "ko": "사용량", "pt": "Utilização", "ar": "الاستخدام"],
        "locUseFreeWebModelsKimiQwenChatgptThroughControlle": ["en": "Use free web models (Kimi, Qwen, ChatGPT) through a controlled browser. Tools (read_file/write_file/…) are emulated over the chat. Automating a third-party service may violate its Terms of Service — enable only if you accept that.", "ru": "Use free web models (Kimi, Qwen, ChatGPT) through a controlled browser. Tools (read_file/write_file/…) are emulated over the chat. Automating a third-party service may violate its Terms of Service — enable only if you accept that."],
        "locWebProvidersBrowser": ["en": "Web providers (browser)", "ru": "Web providers (browser)", "es": "Web providers (browser)", "fr": "Web providers (browser)", "zh": "Web providers (browser)", "ja": "Web providers (browser)", "ko": "Web providers (browser)", "pt": "Web providers (browser)", "ar": "Web providers (browser)"],
        "locWrapLongContentInsideThePreviewAreaAutomaticall": ["en": "Wrap long content inside the preview area automatically.", "ru": "Wrap long content inside the preview area automatically.", "es": "Wrap long content inside the preview area automatically.", "fr": "Wrap long content inside the preview area automatically.", "zh": "Wrap long content inside the preview area automatically.", "ja": "Wrap long content inside the preview area automatically.", "ko": "Wrap long content inside the preview area automatically.", "pt": "Wrap long content inside the preview area automatically."],
        "locWrapLongLines": ["en": "Wrap long lines", "ru": "Wrap long lines", "fr": "Wrap long lines", "de": "Wrap long lines", "zh": "Wrap long lines", "ja": "Wrap long lines", "ko": "Wrap long lines", "pt": "Wrap long lines", "ar": "Wrap long lines"],
        "locUsage1": ["en": "by usage", "ru": "by usage", "es": "by usage", "fr": "by usage", "de": "by usage", "zh": "by usage", "ja": "by usage", "ko": "by usage", "pt": "by usage", "ar": "by usage"],
        "locDefault": ["en": "default", "ru": "default", "es": "predeterminado", "fr": "par défaut", "zh": "默认", "ja": "デフォルト", "ko": "기본값", "pt": "predefinido"],
        "locNow": ["en": "now", "ru": "now", "es": "ahora", "fr": "maintenant", "de": "jetzt", "zh": "现在", "ja": "今", "ko": "지금", "pt": "agora", "ar": "الآن"],
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
