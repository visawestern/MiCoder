import SwiftUI

struct ChatPanelView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var messageStore = MessageStore()
    @StateObject private var messageQueue = MessageQueue()
    @StateObject private var attachmentStore = MessageAttachmentStore()
    @State private var messageText = ""
    @State private var showFilePicker = false
    @State private var streamingText = ""
    @State private var currentAssistantMessageID: String?
    @State private var currentTask: Task<Void, Never>?
    @State private var previousSessionID: String?
    @State private var isChatBottomVisible = true
    @State private var canLoadOlderMessages = false
    @State private var scrolledSessionID: String?
    private let sseClient = SSEClient()
    
    var body: some View {
        VStack(spacing: 0) {
            if !TaskHeaderVisibility.shouldShow(selectedSession: appState.selectedSession) {
                ChatPanelCompactHeader()
            }

            if ChatPanelLayoutLogic.shouldUseCenteredInput(messageCount: messageStore.messages.count) {
                EmptyChatStateView(
                    messageText: $messageText,
                    attachmentStore: attachmentStore,
                    showFilePicker: $showFilePicker,
                    messageQueue: messageQueue,
                    onSend: sendMessage,
                    onStop: stopGeneration,
                    isLoading: appState.isLoading
                )
            } else {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if messageStore.isLoadingOlder {
                                    HStack {
                                        Spacer()
                                        ProgressView().scaleEffect(0.8)
                                        Text("Loading older messages...")
                                            .interfaceFont(size: 12)
                                            .foregroundColor(Color.mimo.textMuted)
                                        Spacer()
                                    }.padding(.vertical, 8)
                                } else if messageStore.hasMoreMessages {
                                    Button("Load earlier messages") {
                                        loadOlderMessages()
                                    }
                                    .buttonStyle(.plain)
                                    .interfaceFont(size: 12, weight: .medium)
                                    .foregroundColor(Color.mimo.cyan)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .onAppear {
                                        guard canLoadOlderMessages else { return }
                                        loadOlderMessages()
                                    }
                                }
                                
                                ForEach(Array(displayMessages.enumerated()), id: \.element.id) { index, message in
                                    if let separator = workedSeparator(before: index, in: displayMessages) {
                                        WorkedTimeSeparator(label: separator)
                                    }
                                    
                                    MessageRow(message: message)
                                        .id(message.id)
                                }

                                Color.clear
                                    .frame(height: 1)
                                    .id(ChatScrollLogic.bottomAnchorID)
                                    .onAppear {
                                        isChatBottomVisible = true
                                        messageStore.isPinnedToBottom = true
                                    }
                                    .onDisappear {
                                        isChatBottomVisible = false
                                        messageStore.isPinnedToBottom = false
                                    }
                            }.padding(.vertical, 16)
                        }
                        .onChange(of: ChatScrollLogic.revision(messages: displayMessages)) { _ in
                            guard ChatScrollLogic.shouldAutoScroll(wasAtBottom: isChatBottomVisible) else {
                                return
                            }
                            DispatchQueue.main.async {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    proxy.scrollTo(ChatScrollLogic.bottomAnchorID, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: messageStore.currentSessionID) { newID in
                            guard ChatScrollLogic.shouldScrollOnSessionChange(
                                oldSessionID: scrolledSessionID,
                                newSessionID: newID
                            ) else { return }
                            scrolledSessionID = newID
                            DispatchQueue.main.async {
                                proxy.scrollTo(ChatScrollLogic.bottomAnchorID, anchor: .bottom)
                            }
                        }
                        .onAppear {
                            guard ChatScrollLogic.shouldScrollOnSessionChange(
                                oldSessionID: scrolledSessionID,
                                newSessionID: messageStore.currentSessionID
                            ) else { return }
                            scrolledSessionID = messageStore.currentSessionID
                            DispatchQueue.main.async {
                                proxy.scrollTo(ChatScrollLogic.bottomAnchorID, anchor: .bottom)
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if ChatScrollLogic.showsScrollToBottomButton(
                                isBottomVisible: isChatBottomVisible,
                                messageCount: displayMessages.count
                            ) {
                                ScrollToBottomButton {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo(ChatScrollLogic.bottomAnchorID, anchor: .bottom)
                                    }
                                }
                                .padding(.trailing, 16)
                                .padding(.bottom, 12)
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }
                        }
                        .animation(.easeOut(duration: 0.15), value: isChatBottomVisible)
                    }

                    ComposerAttachmentPreview(store: attachmentStore)

                    if let pending = appState.pendingQuestionRequest {
                        PlanQuestionCardView(questions: pending.questions) { answers in
                            submitQuestionAnswers(answers)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }

                    BottomInputBar(
                        messageText: $messageText,
                        onSend: sendMessage,
                        onStop: stopGeneration,
                        isLoading: appState.isLoading,
                        attachmentStore: attachmentStore,
                        showFilePicker: $showFilePicker,
                        messageQueue: messageQueue
                    )
                }
            }
        }
        .background(Color.mimo.background)
        .onChange(of: appState.selectedSession?.id) { newSessionID in
            if let sessionID = newSessionID {
                guard SessionReloadLogic.shouldReloadMessages(
                    newSessionID: sessionID,
                    currentSessionID: messageStore.currentSessionID,
                    localMessageCount: messageStore.messages.count,
                    isLoading: appState.isLoading
                ) else { return }
                loadSessionMessages(sessionID: sessionID)
            } else {
                messageStore.clear()
                messageText = ""
                attachmentStore.clear()
            }
        }
        .onChange(of: appState.isLoading) { loading in
            if !loading {
                messageQueue.processNext()
            }
        }
        .onAppear {
            ChatPasteCoordinator.shared.register(store: attachmentStore) { text in
                if messageText.isEmpty {
                    messageText = text
                } else {
                    messageText += text
                }
            }
            messageQueue.setOnProcess { queued in
                Task {
                    await self.sendDirectly(
                        text: queued.text,
                        files: queued.files,
                        images: queued.images,
                        agentModeOverride: queued.type.toAgentMode
                    )
                }
            }
            if let sessionID = appState.selectedSession?.id {
                previousSessionID = sessionID
                loadSessionMessages(sessionID: sessionID)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .editMessage)) { notification in
            guard let messageID = notification.userInfo?["messageId"] as? String,
                  let message = messageStore.messages.first(where: { $0.id == messageID }) else { return }
            loadMessageIntoComposer(message)
        }
        .onReceive(NotificationCenter.default.publisher(for: .resendMessage)) { notification in
            guard let messageID = notification.userInfo?["messageId"] as? String,
                  let message = messageStore.messages.first(where: { $0.id == messageID }) else { return }
            resendMessage(message)
        }
        .onReceive(NotificationCenter.default.publisher(for: .retryMessage)) { notification in
            guard let messageID = notification.userInfo?["messageId"] as? String else { return }
            retryAssistantMessage(messageID: messageID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .stopGeneration)) { _ in
            stopGeneration()
        }
        .onReceive(NotificationCenter.default.publisher(for: .submitPlanQuestionAnswers)) { notification in
            guard let answers = notification.userInfo?["answers"] as? [[String]] else { return }
            submitQuestionAnswers(answers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyEntireChat)) { _ in
            let transcript = ChatCopyLogic.transcript(from: messageStore.messages)
            guard !transcript.isEmpty else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(transcript, forType: .string)
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                for url in urls {
                    let name = url.lastPathComponent
                    let ext = url.pathExtension
                    let type = FileType.from(ext: ext)
                    let path = url.path
                    attachmentStore.appendFile(FileInfo(name: name, type: type, path: path))
                }
            }
        }
    }
    
    private var displayMessages: [Message] {
        MessageDisplayLogic.messagesForDisplay(messageStore.messages)
    }
    
    private func workedSeparator(before index: Int, in messages: [Message]) -> String? {
        guard index > 0 else { return nil }
        let previous = messages[index - 1]
        let current = messages[index]
        let gap = current.timestamp.timeIntervalSince(previous.timestamp)
        guard gap >= 5 else { return nil }
        return SessionSendLogic.workedDurationLabel(since: previous.timestamp, until: current.timestamp)
    }
    
    func loadSessionMessages(sessionID: String) {
        canLoadOlderMessages = false
        // Clear only on a real session switch; refreshing the same session
        // merges incrementally so unchanged rows don't blink.
        let isSameSessionRefresh = messageStore.currentSessionID == sessionID
            && !messageStore.messages.isEmpty
        if !isSameSessionRefresh {
            messageStore.clear()
            messageStore.currentSessionID = sessionID
        }

        Task {
            appState.scheduleGitRefresh(sessionID: sessionID)
            let initialLimit = MessageHistoryPaginationLogic.initialLimit
            var messages: [MimoMessageResponse] = []
            var hasMoreMessages = false
            do {
                let serverMessages = try await appState.mimoClient.getMessages(
                    sessionID: sessionID,
                    limit: initialLimit
                )
                if serverMessages.isEmpty {
                    // No server messages — fall back to the local database only
                    // (never the mimo CLI: the app no longer shells out to mimo).
                    let localMessages = DatabaseBridge.shared.loadMessages(sessionId: sessionID)
                    messages = Array(localMessages.suffix(initialLimit))
                    hasMoreMessages = localMessages.count > initialLimit
                } else {
                    messages = serverMessages
                    hasMoreMessages = MessageHistoryPaginationLogic.hasMore(
                        receivedCount: serverMessages.count,
                        requestedLimit: initialLimit
                    )
                }
            } catch {
                // Server unreachable — use the local database, not the mimo CLI.
                let localMessages = DatabaseBridge.shared.loadMessages(sessionId: sessionID)
                messages = Array(localMessages.suffix(initialLimit))
                hasMoreMessages = localMessages.count > initialLimit
            }
            let loadedMessages = messages
            let canLoadMore = hasMoreMessages
            await MainActor.run {
                guard messageStore.currentSessionID == sessionID else { return }
                appState.applySessionPlan(from: loadedMessages)
                if let selections = SessionSendLogic.restoreSelections(from: loadedMessages) {
                    appState.applySendSelections(selections)
                }
                
                messageStore.mergeLatestMessages(from: loadedMessages)
                if !isSameSessionRefresh {
                    messageStore.currentHistoryLimit = initialLimit
                }
                messageStore.hasMoreMessages = canLoadMore
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    guard messageStore.currentSessionID == sessionID else { return }
                    canLoadOlderMessages = true
                }
            }
        }
    }
    
    func sendMessage() {
        guard MessageSendValidation.canSend(
            text: messageText,
            images: attachmentStore.attachedImages,
            files: attachmentStore.attachedFiles
        ) else { return }

        // Slash command interception (plan Раздел 5 Блок 3 п.30). Commands that
        // don't map to plain text are handled locally and short-circuit the send;
        // instruction-injecting commands rewrite the outgoing text.
        if messageText.hasPrefix("/") {
            let executor = SlashCommandExecutor(hasGitRepo: !(appState.selectedWorkspace?.path ?? "").isEmpty)
            switch executor.execute(messageText) {
            case .setSessionGoal(let goal):
                appState.setCurrentSessionGoal(goal)
                messageText = ""
                messageStore.append(Message(role: .assistant, content: "🎯 Goal set: \(goal)", isFinished: true))
                return
            case .showSessionGoal:
                let g = appState.currentSessionGoal ?? "(no goal set)"
                messageText = ""
                messageStore.append(Message(role: .assistant, content: "🎯 Current goal: \(g)", isFinished: true))
                return
            case .gitRequiredError(let cmd):
                messageText = ""
                messageStore.append(Message(role: .assistant, content: "Command /\(cmd) needs a git repository in this workspace.", isFinished: true))
                return
            case .unknownCommand(let name, let available):
                messageText = ""
                messageStore.append(Message(role: .assistant, content: "Unknown command /\(name). Available: \(available.map { "/\($0)" }.joined(separator: ", "))", isFinished: true))
                return
            case .injectInstruction(let instruction):
                messageText = instruction
            case .enterPlanMode, .openCommitComposer, .createPullRequest, .requestReview, .showContext:
                // These map to existing flows; fall through sending the command
                // text so downstream handlers/agent can act on it.
                break
            case .passthrough:
                break
            }
        }
        if let error = SendReadinessLogic.connectionValidationError(
            serverConnected: appState.serverConnected,
            selectedProviderID: appState.selectedProviderID,
            customProviders: appState.customProviders,
            localProviderIDs: appState.localProviderIDs,
            webProviderIDs: appState.webProviderIDs
        ) {
            messageStore.append(
                Message(role: .assistant, content: error, isFinished: true)
            )
            return
        }
        if let error = SendReadinessLogic.sendValidationError(
            modelID: appState.selectedModel,
            providerID: appState.selectedProviderID.isEmpty ? nil : appState.selectedProviderID
        ) {
            messageStore.append(
                Message(role: .assistant, content: error, isFinished: true)
            )
            return
        }
        
        let text = messageText
        let files = attachmentStore.attachedFiles
        let images = attachmentStore.attachedImages
        messageText = ""
        attachmentStore.clear()
        
        if appState.isLoading {
            messageQueue.enqueue(
                text: text,
                files: files,
                images: images,
                type: MessageType(from: appState.agentMode)
            )
            return
        }
        
        Task {
            await sendDirectly(text: text, files: files, images: images)
        }
    }
    
    func sendDirectly(
        text: String,
        files: [FileInfo],
        images: [ClipboardImage] = [],
        agentModeOverride: AgentMode? = nil
    ) async {
        if let error = SendReadinessLogic.connectionValidationError(
            serverConnected: appState.serverConnected,
            selectedProviderID: appState.selectedProviderID,
            customProviders: appState.customProviders,
            localProviderIDs: appState.localProviderIDs,
            webProviderIDs: appState.webProviderIDs
        ) {
            await MainActor.run {
                messageStore.append(
                    Message(role: .assistant, content: error, isFinished: true)
                )
            }
            return
        }

        let assistantID = UUID().uuidString
        let selectedID = appState.selectedSession?.id
        let messageID = MessageIDGenerator.next()
        let agentMode = agentModeOverride ?? appState.agentMode
        let sendOptions = SessionSendLogic.buildSendOptions(
            agentMode: agentMode,
            selectedVariant: appState.selectedVariant.isEmpty ? nil : appState.selectedVariant,
            modelID: appState.selectedModel,
            selectedProviderID: appState.selectedProviderID,
            providers: appState.serverProviders,
            customProviders: appState.customProviders,
            messageID: messageID,
            accessLevel: appState.accessLevel
        )
        if let error = SendReadinessLogic.sendValidationError(
            modelID: appState.selectedModel,
            providerID: sendOptions.providerID
        ) {
            await MainActor.run {
                appState.isLoading = false
                appState.isStreaming = false
                messageStore.update(id: assistantID) { msg in
                    msg.content = error
                    msg.isStreaming = false
                    msg.isFinished = true
                }
            }
            return
        }

        let userMessage = Message(
            role: .user,
            content: text,
            files: files.isEmpty ? nil : files,
            parts: MessagePartsBuilder.displayParts(text: text, images: images)
        )
        await MainActor.run { messageStore.append(userMessage) }

        let parts = MessagePartsBuilder.build(text: text, files: files, images: images)
        
        await MainActor.run {
            currentAssistantMessageID = assistantID
            messageStore.append(Message(id: assistantID, role: .assistant, content: "", isStreaming: true))
            appState.isLoading = true
            appState.isStreaming = true
            streamingText = ""
        }
        
        // Resolve how this message is delivered based on the selected provider
        // (web / local / custom OpenAI-compatible / ACP / serve) so sending
        // adapts to the current model instead of only the serve path.
        let route = SendRouteResolver.route(
            selectedProviderID: appState.selectedProviderID,
            selectedModel: appState.selectedModel,
            serverConnected: appState.serverConnected,
            isACP: appState.isSelectedACPProvider,
            customProviders: appState.customProviders,
            localProviders: LocalProviderLogic.load(),
            webProviderIDs: appState.webProviderIDs
        )

        do {
            // ── Local / custom OpenAI-compatible branch ──────────
            if case .openAICompatible(let baseURL, let apiKey, let model) = route {
                let params = ModelCallParametersStore.parameters(for: model)
                // Prior turns = everything except the just-appended user message
                // and the empty assistant placeholder (audit P1 — carry history).
                let prior = await MainActor.run { () -> [ChatHistoryBuilder.Turn] in
                    let msgs = messageStore.messages
                    let history = msgs.count >= 2 ? Array(msgs.dropLast(2)) : []
                    return history.map { ChatHistoryBuilder.Turn(role: roleString($0.role), content: $0.content, isFinished: $0.isFinished) }
                }
                let msgs = ChatHistoryBuilder.messages(
                    systemPrompt: params.systemPrompt, priorTurns: prior, userText: text
                )
                let answer = try await DirectChatClient.send(
                    baseURL: baseURL, apiKey: apiKey, model: model,
                    messages: msgs, parameters: params
                )
                await MainActor.run {
                    self.appState.isLoading = false
                    self.appState.isStreaming = false
                    self.streamingText = ""
                    self.messageStore.update(id: assistantID) { msg in
                        msg.content = answer
                        msg.isFinished = true
                        msg.isStreaming = false
                    }
                    self.currentAssistantMessageID = nil
                }
                return
            }

            // ── Web-chat provider branch (browser tool-emulation) ─
            if case .web(let configID) = route,
               let cfg = WebProviderStore.load().first(where: { $0.id == configID }) {
                await runWebChatTurn(config: cfg, text: text, assistantID: assistantID)
                return
            }

            // ── ACP provider branch ──────────────────────────────
            if appState.isSelectedACPProvider, let acpClient = appState.acpClient {
                // Build ACP request messages from user text + files
                let acpMessages = buildACPMessages(text: text, files: files, images: images)
                let acpAgent = SessionSendLogic.sendMode(for: agentModeOverride ?? appState.agentMode)
                let acpVariant = appState.selectedVariant.isEmpty ? nil : appState.selectedVariant

                // Non-streaming send via ACP client
                let response = try await acpClient.sendChatCompletion(
                    messages: acpMessages,
                    model: appState.selectedModel,
                    agent: acpAgent,
                    variant: acpVariant,
                    stream: false
                )

                // Convert ACP response to message text
                let responseText = response.choices.first?.message.content ?? ""
                let reasoningText = response.choices.first?.message.reasoning

                await MainActor.run {
                    self.appState.isLoading = false
                    self.appState.isStreaming = false
                    self.streamingText = ""
                    self.messageStore.update(id: assistantID) { msg in
                        msg.content = responseText
                        msg.reasoning = reasoningText ?? ""
                        msg.isFinished = true
                        msg.isStreaming = false
                    }
                    self.currentAssistantMessageID = nil
                    // No session for ACP — task complete is still useful
                    self.appState.notificationService.taskCompleted(
                        sessionTitle: String(text.prefix(50)),
                        sessionID: assistantID
                    )
                }
                return
            }

            // ── Standard MiMo Serve branch ───────────────────────
            let sessionID: String
            if SessionSendLogic.shouldCreateNewSession(selectedSessionID: selectedID) {
                let session = try await appState.mimoClient.createSession(title: String(text.prefix(50)))
                sessionID = session.id
                await MainActor.run {
                    messageStore.currentSessionID = sessionID
                    appState.registerSessionFromServer(
                        id: session.id,
                        title: session.title,
                        directory: appState.selectedWorkspace?.path ?? session.directory
                    )
                }
            } else {
                sessionID = SessionSendLogic.resolvedSessionID(selectedSessionID: selectedID, newlyCreatedID: "")
            }

            await MainActor.run { messageStore.currentSessionID = sessionID }
            
            await MainActor.run {
                sseClient.onEvent = { type, payload in
                    Task { @MainActor in
                        self.handleSSEEvent(type: type, payload: payload)
                    }
                }
            }
            
            if let url = URL(string: "http://127.0.0.1:\(appState.serverPort)/global/event") {
                sseClient.connect(url: url)
            }
            
            let responseMessages = try await appState.mimoClient.sendMessage(
                sessionID: sessionID,
                parts: parts,
                options: sendOptions
            )
            appState.scheduleGitRefresh(sessionID: sessionID)
            
            await MainActor.run {
                let hasPendingQuestion = self.appState.pendingQuestionRequest != nil
                let mergedParts = messageStore.messages.first(where: { $0.id == self.currentAssistantMessageID })?.parts ?? []
                let waitingForQuestion = hasPendingQuestion || PlanQuestionLogic.hasPendingQuestions(in: mergedParts)

                if SessionSendLogic.shouldAwaitSSE(
                    responseMessages: responseMessages,
                    hasPendingQuestion: waitingForQuestion
                ) {
                    return
                }

                if !waitingForQuestion {
                    self.sseClient.disconnect()
                }

                if let firstResponse = SessionSendLogic.assistantResponse(from: responseMessages) {
                    let merged = MessageResponseMergeLogic.mergedAssistantMessage(
                        existing: messageStore.messages.first(where: { $0.id == self.currentAssistantMessageID }) ?? Message(role: .assistant, content: ""),
                        serverParts: firstResponse.parts,
                        serverText: firstResponse.textContent,
                        streamingText: self.streamingText
                    )
                    self.streamingText = merged.content
                    self.messageStore.update(id: self.currentAssistantMessageID ?? "") { msg in
                        msg.content = merged.content
                        msg.reasoning = merged.reasoning
                        msg.parts = merged.parts
                        msg.isFinished = !waitingForQuestion
                        msg.isStreaming = waitingForQuestion
                    }
                    self.syncExecutionSteps(from: merged.parts)
                }

                if waitingForQuestion {
                    self.appState.isLoading = false
                    self.appState.isStreaming = false
                } else {
                    self.appState.isLoading = false
                    self.appState.isStreaming = false
                    self.streamingText = ""
                    self.currentAssistantMessageID = nil
                    self.refreshGitForCurrentSession()
                    // Notify: task complete
                    if let session = self.appState.selectedSession {
                        self.appState.notificationService.taskCompleted(
                            sessionTitle: session.title,
                            sessionID: session.id
                        )
                    }
                }
            }
        } catch {
            if case MimoServeError.sessionBusy = error {
                await MainActor.run {
                    self.messageStore.update(id: assistantID) { msg in
                        msg.content = "Session busy, aborting and retrying..."
                        msg.isStreaming = true
                    }
                    self.appState.notificationService.sessionBusy()
                }
                if let sessionID = messageStore.currentSessionID {
                    try? await appState.mimoClient.abortSession(id: sessionID)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                await MainActor.run {
                    self.messageStore.update(id: assistantID) { msg in
                        msg.content = ""
                    }
                }
                await sendDirectly(text: text, files: files, images: images, agentModeOverride: agentModeOverride)
                return
            }
            await MainActor.run {
                self.appState.isLoading = false
                self.appState.isStreaming = false
                self.sseClient.disconnect()
                self.messageStore.update(id: assistantID) { msg in
                    msg.content = "Error: \(error.localizedDescription)"
                    msg.isFinished = true
                    msg.isStreaming = false
                }
                self.refreshGitForCurrentSession()
            }
        }
    }

    private func refreshGitForCurrentSession() {
        appState.scheduleGitRefresh(sessionID: messageStore.currentSessionID)
    }
    
    func stopGeneration() {
        currentTask?.cancel()
        currentTask = nil
        sseClient.disconnect()
        messageQueue.cancelAll()

        if let sessionID = messageStore.currentSessionID {
            Task {
                try? await appState.mimoClient.abortSession(id: sessionID)
            }
        }

        appState.isLoading = false
        appState.isStreaming = false
        
        if let id = currentAssistantMessageID {
            messageStore.update(id: id) { msg in
                msg.isFinished = true
                msg.isStreaming = false
                if msg.content.isEmpty {
                    msg.content = "Generation stopped"
                }
            }
        }
        
        currentAssistantMessageID = nil
        streamingText = ""
        appState.notificationService.generationStopped()
        refreshGitForCurrentSession()
    }
    
    func loadOlderMessages() {
        guard let sessionID = messageStore.currentSessionID else { return }
        guard !messageStore.isLoadingOlder else { return }  // Prevent cascade

        Task {
            canLoadOlderMessages = false
            await messageStore.loadHistory(sessionID: sessionID, client: appState.mimoClient)
            await MainActor.run {
                canLoadOlderMessages = messageStore.hasMoreMessages
            }
        }
    }

    func loadMessageIntoComposer(_ message: Message) {
        let draft = MessageEditLogic.draft(from: message)
        messageText = draft.text
        attachmentStore.replaceImages(draft.images)
        attachmentStore.replaceFiles(draft.files)
    }

    func resendMessage(_ message: Message) {
        guard MessageEditLogic.canResend(message) else { return }
        let draft = MessageEditLogic.draft(from: message)
        guard MessageSendValidation.canSend(
            text: draft.text,
            images: draft.images,
            files: draft.files
        ) else { return }

        if appState.isLoading {
            messageQueue.enqueue(
                text: draft.text,
                files: draft.files,
                images: draft.images,
                type: MessageType(from: appState.agentMode)
            )
            return
        }

        Task {
            await sendDirectly(text: draft.text, files: draft.files, images: draft.images)
        }
    }

    // MARK: - ACP Message Building

    /// Builds `[ACPRequestMessage]` from the user's text, file references and
    /// images. Uses ACPMessageBuilder so real image bytes (data URLs) are sent
    /// instead of a "[N image(s) attached]" placeholder (plan Раздел 9 Блок 2).
    /// Run one turn against a web-chat provider through an in-app WKWebView
    /// bridge + WebChatDriver, presenting events (streaming/tool/captcha/final)
    /// into the chat so the message actually reaches the web model and shows a
    /// real response (plan Раздел 12). Restores the captured session cookies.
    @MainActor
    private func runWebChatTurn(config: WebProviderConfig, text: String, assistantID: String) async {
        #if canImport(WebKit)
        // Reuse (or lazily create) a persistent web view for this provider.
        let webView = appState.webView(for: config)
        let selectors = WebVendorSelectors(
            input: "textarea, div[contenteditable='true']",
            sendButton: "button[type='submit'], button[aria-label*='end'], button[data-testid='send-button']",
            responseContainer: "div[data-message-author-role='assistant'], div[class*='markdown'], div[class*='message']",
            stopButton: "button[aria-label*='top'], button[data-testid='stop-button'], button[class*='stop']"
        )
        let bridge = WKWebViewBrowserBridge(webView: webView, selectors: selectors)
        // Restore cookies captured at login so the session is authenticated.
        if let store = WebSessionManager.restore(providerId: config.id,
                                                 homeDirectory: FileManager.default.homeDirectoryForCurrentUser) {
            try? await bridge.setCookies(store.cookies)
        }
        try? await bridge.navigate(to: config.chatURL)

        // Discover the vendor's real models from the model dropdown (audit P13 —
        // WebModelListParser was never called, so discoveredModels stayed empty
        // and the UI showed vendor defaults). Best-effort; keeps defaults if the
        // dropdown isn't found.
        let modelDropdownSelector = "button[class*='model'], div[class*='model-select'], button[data-testid*='model-switcher'], div[class*='model-selector']"
        if let dropdownText = try? await bridge.readText(selector: modelDropdownSelector), !dropdownText.isEmpty {
            let updated = WebModelListParser.updated(config, withDropdownText: dropdownText)
            if !updated.discoveredModels.isEmpty {
                let merged = WebProviderStore.upsert(updated, in: WebProviderStore.load())
                WebProviderStore.save(merged)
            }
        }

        let executor = ProjectWebToolExecutor(projectRoot: appState.selectedWorkspace?.path ?? FileManager.default.currentDirectoryPath)
        let driver = WebChatDriver(bridge: bridge, executor: executor, selectors: selectors,
                                   config: config, projectRoot: appState.selectedWorkspace?.path ?? "")

        // Send the tool-protocol preamble only on the first turn of a session
        // (audit P2); later turns continue the same web conversation.
        let isFirst = appState.webSessionIsFirstTurn(config.id)
        appState.markWebSessionStarted(config.id)
        await driver.runTurn(userMessage: text, isFirstMessage: isFirst) { event in
            Task { @MainActor in
                switch WebChatEventPresenter.present(event) {
                case .answer(let t):
                    self.messageStore.update(id: assistantID) { m in
                        m.content = t; m.isFinished = true; m.isStreaming = false
                    }
                    self.finishWebTurn()
                case .status(let s):
                    self.streamingText = s
                    // A logout/session-restart means the next turn must re-seed.
                    if WebChatEventPresenter.blocksUntilUserAction(event) || s.contains("fresh session") {
                        self.appState.resetWebSession(config.id)
                    }
                case .captcha(let b64, let note):
                    self.messageStore.update(id: assistantID) { m in
                        m.content = "\(note)\n\n![captcha](data:image/png;base64,\(b64))"
                        m.isStreaming = false
                    }
                case .error(let e):
                    self.messageStore.update(id: assistantID) { m in
                        m.content = "Web provider error: \(e)"; m.isFinished = true; m.isStreaming = false
                    }
                    self.finishWebTurn()
                case .none:
                    break
                }
            }
        }
        finishWebTurn()
        #else
        messageStore.update(id: assistantID) { m in
            m.content = "Web providers require WebKit (macOS)."; m.isFinished = true; m.isStreaming = false
        }
        #endif
    }

    private func roleString(_ role: MessageRole) -> String {
        switch role {
        case .user: return "user"
        case .assistant: return "assistant"
        case .system: return "system"
        }
    }

    @MainActor
    private func finishWebTurn() {
        appState.isLoading = false
        appState.isStreaming = false
        streamingText = ""
        currentAssistantMessageID = nil
    }

    private func buildACPMessages(text: String, files: [FileInfo], images: [ClipboardImage]) -> [ACPRequestMessage] {
        let message = ACPMessageBuilder.buildUserMessage(
            text: text,
            fileNames: files.map { $0.name },
            images: images.map { (mimeType: $0.mimeType, base64: $0.base64) }
        )
        return [message]
    }

    func submitQuestionAnswers(_ answers: [[String]]) {
        guard let pending = appState.pendingQuestionRequest,
              !pending.requestID.isEmpty else { return }
        let requestID = pending.requestID

        Task {
            do {
                try await appState.mimoClient.replyToQuestion(requestID: requestID, answers: answers)
                await MainActor.run {
                    appState.pendingQuestionRequest = nil
                    appState.isLoading = true
                    appState.isStreaming = true
                    if let assistantID = currentAssistantMessageID {
                        messageStore.update(id: assistantID) { msg in
                            msg.isStreaming = true
                            msg.isFinished = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    appState.isLoading = false
                    appState.isStreaming = false
                    if let assistantID = currentAssistantMessageID {
                        messageStore.update(id: assistantID) { msg in
                            msg.content = "Question reply failed: \(error.localizedDescription)"
                            msg.isStreaming = false
                            msg.isFinished = true
                        }
                    }
                }
            }
        }
    }

    func retryAssistantMessage(messageID: String) {
        guard let index = messageStore.messages.firstIndex(where: { $0.id == messageID }) else { return }
        for i in (0..<index).reversed() {
            if messageStore.messages[i].role == .user {
                resendMessage(messageStore.messages[i])
                return
            }
        }
    }
    
    @MainActor
    func handleSSEEvent(type: String, payload: [String: Any]) {
        guard let props = payload["properties"] as? [String: Any] else { return }
        let sessionID = props["sessionID"] as? String ?? ""
        
        if sessionID != messageStore.currentSessionID { return }
        
        switch type {
        case "question.asked":
            if let pending = PlanQuestionLogic.parseQuestionAskedEvent(properties: props) {
                appState.pendingQuestionRequest = pending
                pauseForPendingQuestion()
                if let assistantID = currentAssistantMessageID {
                    messageStore.update(id: assistantID) { msg in
                        msg.isStreaming = false
                        msg.isFinished = false
                    }
                }
            }

        case "question.replied", "question.rejected":
            appState.pendingQuestionRequest = nil

        case "message.part.delta":
            let delta = props["delta"] as? String ?? ""
            let field = props["field"] as? String ?? ""
            
            if field == "text" && !delta.isEmpty {
                streamingText += delta
                messageStore.update(id: currentAssistantMessageID ?? "") { msg in
                    msg.content = streamingText
                }
            }
            
        case "message.part.updated":
            guard let part = props["part"] as? [String: Any],
                  let partType = part["type"] as? String else { break }

            messageStore.update(id: currentAssistantMessageID ?? "") { msg in
                if let parsed = PlanQuestionLogic.parseOpenCodeToolPart(part) {
                    PlanQuestionLogic.upsertToolCall(
                        &msg.parts,
                        name: parsed.toolName,
                        args: parsed.argsJSON,
                        result: parsed.result,
                        callID: parsed.callID
                    )
                    if PlanQuestionLogic.isQuestionTool(parsed.toolName), parsed.isPending, !parsed.questions.isEmpty {
                        msg.isStreaming = false
                        msg.isFinished = false
                        self.pauseForPendingQuestion()
                    }
                    self.syncExecutionSteps(from: msg.parts)
                    return
                }

                switch partType {
                case "text":
                    if let text = part["text"] as? String, !text.isEmpty {
                        streamingText = text
                        msg.content = text
                        MessageResponseMergeLogic.upsertTextPart(&msg.parts, text: text)
                    }
                case "reasoning":
                    if let text = part["text"] as? String, !text.isEmpty {
                        msg.reasoning = text
                        MessageResponseMergeLogic.upsertReasoningPart(&msg.parts, text: text)
                    }
                case "tool-invocation", "tool-call":
                    let toolName = part["toolName"] as? String ?? part["name"] as? String ?? "tool"
                    let input = part["input"] as? String ?? part["args"] as? String ?? part["arguments"] as? String ?? "{}"
                    let result = part["result"] as? String
                    PlanQuestionLogic.upsertToolCall(&msg.parts, name: toolName, args: input, result: result, callID: part["callID"] as? String ?? part["id"] as? String)
                    if PlanQuestionLogic.isQuestionTool(toolName), result == nil {
                        msg.isStreaming = false
                        msg.isFinished = false
                        self.pauseForPendingQuestion()
                    }
                    if toolName.lowercased() == "todowrite",
                       let steps = SessionPlanParser.steps(fromTodoWriteJSON: input) {
                        appState.currentSteps = steps
                        appState.showGoal = true
                    }
                case "step-start":
                    msg.parts.append(.stepStart)
                    appState.showGoal = true
                case "step-finish":
                    msg.parts.append(.stepFinish)
                default:
                    break
                }
                self.syncExecutionSteps(from: msg.parts)
            }
            
        case "session.status":
            if let status = props["status"] as? [String: String],
               status["type"] == "idle" {
                finishStreaming()
            }
            
        case "session.idle":
            finishStreaming()
            
            case "message.updated":
                if let info = props["info"] as? [String: Any],
                   let role = info["role"] as? String,
                   role == "assistant",
                   let messageID = info["id"] as? String {
                    let reconciledID = SessionSendLogic.reconcileAssistantMessageID(localID: currentAssistantMessageID, serverID: messageID)
                    if currentAssistantMessageID != reconciledID {
                        // Store the server-assigned ID as the current assistant message ID
                        // and mark the local message for DB reconciliation
                        if let localID = currentAssistantMessageID {
                            messageStore.update(id: localID) { msg in
                                msg.serverID = reconciledID
                                if msg.content.isEmpty {
                                    msg.content = streamingText
                                }
                            }
                        }
                        currentAssistantMessageID = reconciledID
                    }
                if let finish = info["finish"] as? String, finish == "stop" {
                    messageStore.setFinished(id: messageID)
                }
            }
            
        default:
            break
        }
    }
    
    @MainActor
    private func pauseForPendingQuestion() {
        appState.isLoading = false
        appState.isStreaming = false
    }

    @MainActor
    private func syncExecutionSteps(from parts: [MessagePartContent]) {
        let synced = ExecutionStepSyncLogic.steps(from: parts, existing: appState.currentSteps)
        guard !synced.isEmpty else { return }
        appState.currentSteps = ExecutionStepSyncLogic.mergedSteps(existing: appState.currentSteps, incoming: synced)
        appState.showGoal = true
    }

    @MainActor
    private func finishStreaming() {
        guard appState.pendingQuestionRequest == nil else { return }
        appState.isLoading = false
        appState.isStreaming = false
        sseClient.disconnect()
        
        messageStore.setFinished(id: currentAssistantMessageID ?? "")
        
        if streamingText.isEmpty {
            messageStore.update(id: currentAssistantMessageID ?? "") { msg in
                if msg.content.isEmpty {
                    msg.content = "Task completed"
                }
            }
        }
        streamingText = ""
        currentAssistantMessageID = nil
        refreshGitForCurrentSession()
    }
}

/// Telegram-style floating button that jumps the chat back to the latest message.
struct ScrollToBottomButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.down")
                .interfaceFont(size: 14, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.mimo.surface)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    Circle().stroke(Color.mimo.border.opacity(isHovering ? 0.9 : 0.5), lineWidth: 1)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("Scroll to latest message")
    }
}
