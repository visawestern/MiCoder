# Devil's Advocate Audit — Round 25 (2026-08-07)

## Summary

- **Status**: 1 issue found (code style / readability), 1 fixed, 0 remaining
- **Tests**: 1726 tests / 236 suites — all green
- **Build**: `swift build` — green

## Problems Found & Fixed

### P5 — Misleading indentation in ChatPanelView.handleSSEEvent (LOW)

**File**: `MiCoder/Sources/Views/ChatPanelView.swift:1220-1242`

**Problem**: In the `"message.updated"` SSE event handler, the `if let finish = info["finish"]` block was indented as if it were inside the `if currentAssistantMessageID != reconciledID` block, but it actually belonged to the outer `if let info` block. The code was *correct* (Swift's `if let` chain keeps `info` and `messageID` in scope), but the misleading indentation made it look like dead code or a logic error during review.

**Why real**: Readability matters for maintainability — a future reader could "fix" what they think is a bug and introduce a real one.

**Fix**: Corrected the indentation so the `if let finish` block is clearly inside the `if let info` block.

## Files Changed

| File | Change |
|------|--------|
| `MiCoder/Sources/Views/ChatPanelView.swift` | P5 fix: corrected indentation in `handleSSEEvent` |

## Areas Audited & Found Clean

### Views Layer
- `ChatPanelView.swift` (1348 lines) — send flow, SSE handling, slash commands, web chat turns, ACP branch, message queue, draft persistence
- `SidebarView.swift` (970 lines) — workspace list, navigation, notifications, archive, filtering, grouping
- `SettingsView.swift` (3010 lines) — tab routing, all 10 visible tabs, provider management, skills/MCP management
- `ContentView.swift` — shell routing, sheets, modals
- `BottomPanelView.swift` — terminal + git tabs
- `RightPanelView.swift` — git panel, progress display
- `TaskHeaderView.swift`, `TopBarView.swift`, `StatusBarView.swift` — header components

### Services Layer
- `MessageDisplayLogic.swift` — thinking folding, display filtering, reasoning dedup
- `MessagePartsBuilder.swift` — part building for send + display
- `SSEClient.swift` — SSE streaming
- `GitRepository.swift` — git operations, push with upstream detection
- `AgentResourceInstaller.swift` — skill/MCP install
- `AgentResourceRegistryManager.swift` — skill/MCP registry
- `AgentResourcesLoader.swift` — skill/MCP loading
- `AccessLevelPermissionLogic.swift` — permission mapping
- `SelectionRestoreLogic.swift` — sticky preferences
- `SlashCommandExecutor.swift` — slash command dispatch
- `ProjectRegistryLogic.swift` — project registry dedup/relink
- `ProjectUndoManager.swift` — per-project undo
- `UndoRedoManager.swift` — legacy global undo
- `LocalProviderConfig.swift` — local provider model
- `UsageStatisticsAggregator.swift` — usage stats
- `AppLocalization.swift` — localization keys + translations
- `DatabaseManager.swift` — global SQLite storage
- `ProjectDatabaseManager.swift` — per-project SQLite storage
- `DatabaseBridge.swift` — DB routing bridge
- `SQLiteSafeQuery.swift` — safe row iteration
- `ProviderSettingsLogic.swift` — provider/model resolution
- `SessionSendLogic.swift` — send options building
- `SendRouteResolver.swift` — send route resolution
- `DirectChatClient.swift` — OpenAI-compatible HTTP client
- `ChatHistoryBuilder.swift` — conversation history building
- `MessageStore.swift` — message list management
- `MessageQueue.swift` — message queue
- `ModelCallParameters.swift` — per-model call parameters
- `NotificationService.swift` — notifications
- `GitRefreshScheduler.swift` — git refresh scheduling
- `ProjectFilesCacheLogic.swift` — file list cache
- `ProjectFileScanner.swift` — file scanning
- `ProjectFileIndexLogic.swift` — file indexing
- `ProjectSnapshotManager.swift` — file snapshots
- `ProjectAutoBackupLogic.swift` — auto-backup
- `ProjectBackupLogic.swift` — backup/restore
- `ProjectStorageAdmin.swift` — storage administration
- `ProjectDeleteConfirmation.swift` — delete confirmation
- `ProjectHistoryExporter.swift` — history export
- `ProjectOpenIntegrity.swift` — open-time integrity check
- `ProjectShellRunner.swift` — shell command execution
- `ProjectWebToolExecutor.swift` — web tool execution
- `WebToolProtocolEmulator.swift` — tool protocol emulation
- `WebToolAccessGate.swift` — tool access gating
- `WebChatDriver.swift` — web chat driver
- `WebSessionManager.swift` — web session persistence
- `WebProviderConfig.swift` — web provider config
- `WebProviderConnectivity.swift` — web provider connectivity
- `WebModelDiscovery.swift` — web model discovery
- `WebModelListParser.swift` — web model list parsing
- `WebPromptChunker.swift` — prompt chunking
- `WebSessionLogic.swift` — web session logic
- `WebChatEventPresenter.swift` — web event presentation
- `WKWebViewBrowserBridge.swift` — WKWebView bridge
- `BrowserAutomationBridge.swift` — browser automation
- `ACPClient.swift` — ACP protocol client
- `ACPMessageBuilder.swift` — ACP message building
- `ACPMessageTypes.swift` — ACP message types
- `GitHubCLIService.swift` — GitHub CLI integration
- `GitPublishFlowLogic.swift` — publish flow
- `CommitMessageComposer.swift` — commit message generation
- `GitignoreEntryLogic.swift` — gitignore parsing
- `GitRefreshCoalescer.swift` — git refresh coalescing
- `KeychainManager.swift` — keychain access
- `PasteboardAttachmentDetector.swift` — pasteboard detection
- `ClipboardPasteLogic.swift` — clipboard paste
- `ChatPasteRoutingLogic.swift` — paste routing
- `ChatPasteCoordinator.swift` — paste coordination
- `ChatCopyLogic.swift` — chat copy
- `ChatScrollLogic.swift` — scroll behavior
- `ClipboardImage.swift` — clipboard image handling
- `FileDropLogic.swift` — file drop handling
- `AttachmentImportExecutor.swift` — attachment import
- `MessageAttachmentStore.swift` — attachment store
- `MessageEditLogic.swift` — message edit
- `MessageHistoryPaginationLogic.swift` — history pagination
- `MessageResponseMergeLogic.swift` — response merging
- `MessageContentSanitizerLogic.swift` — content sanitization
- `MessageIDGenerator.swift` — message ID generation
- `MessageRowLayoutLogic.swift` — message row layout
- `MessageSendOptions.swift` — send options
- `MessageQueue.swift` — message queue
- `ModelSettingsLayoutLogic.swift` — settings layout
- `MimoServeClient.swift` — MiMo Serve API client
- `MimoServeConnectionManager.swift` — connection management
- `NotificationService.swift` — notifications
- `PasteRoutingDecision.swift` — paste routing decision
- `PasteDebugTrace.swift` — paste debug tracing
- `PlanQuestionLogic.swift` — plan question parsing
- `PlanQuestionWizardLogic.swift` — plan question wizard
- `ProviderAutoDetector.swift` — provider auto-detection
- `ProviderCapabilityGates.swift` — capability gates
- `ProviderOption.swift` — provider option model
- `ProviderSelectionLogic.swift` — provider selection cascade
- `SearchPaletteLogic.swift` — search palette
- `SecurityThemeLogic.swift` — security theme
- `SendReadinessLogic.swift` — send readiness
- `SessionContextLoader.swift` — session context loading
- `SessionPlanParser.swift` — session plan parsing
- `SessionReloadLogic.swift` — session reload
- `SessionSendLogic.swift` — session send logic
- `SidebarGroupingLogic.swift` — sidebar grouping
- `SidebarResizeLogic.swift` — sidebar resize
- `SidebarWorkspaceLogic.swift` — sidebar workspace logic
- `SlashCommandDispatcher.swift` — slash command dispatch
- `SlashCommandRegistry.swift` — slash command registry
- `SpoilerExpandLogic.swift` — spoiler expand
- `StorageAuditLog.swift` — storage audit log
- `StorageResetLogic.swift` — storage reset
- `TerminalFontResolver.swift` — terminal font resolution
- `ToolCallPresentationLogic.swift` — tool call presentation
- `UsageStatisticsAggregator.swift` — usage statistics
- `WorkspaceListBuilder.swift` — workspace list building
- `LocalizationRuntime.swift` — localization runtime
- `InputCardLayoutLogic.swift` — input card layout
- `InputCommandTriggerLogic.swift` — input command trigger
- `InputDropdownDataSource.swift` — input dropdown data source
- `InputFieldHeightLogic.swift` — input field height
- `LanguagePickerLogic.swift` — language picker logic
- `MCPHealthCheckLogic.swift` — MCP health check
- `ExecutionStepSyncLogic.swift` — execution step sync
- `DropdownKeyboardLogic.swift` — dropdown keyboard navigation

## Verification

```bash
swift build   # green
swift test    # 1726 tests / 236 suites — green
```

## Next Round

Continue with:
1. Integration testing — verify end-to-end flows work together
2. Performance audit — check for main-thread blocking, memory leaks
3. Security audit — verify input validation, path safety, API key handling
4. Documentation audit — verify all docs match actual behavior
