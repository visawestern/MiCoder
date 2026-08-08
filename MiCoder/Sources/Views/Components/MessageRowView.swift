import SwiftUI

private enum MessageContentSegment: Identifiable {
    case part(MessagePartContent)
    case toolCalls([ToolCallInspectorStep])

    var id: String {
        switch self {
        case .part(let part):
            return "part-\(part.id)"
        case .toolCalls(let calls):
            return "tools-\(calls.first?.id ?? "empty")"
        }
    }

    static func build(from parts: [MessagePartContent]) -> [MessageContentSegment] {
        var segments: [MessageContentSegment] = []
        var calls: [ToolCallInspectorStep] = []

        func flushCalls() {
            guard !calls.isEmpty else { return }
            segments.append(.toolCalls(calls))
            calls = []
        }

        for part in parts {
            if case .toolCall(let name, let args, let result, _) = part {
                calls.append(
                    ToolCallInspectorStep(
                        id: part.id,
                        name: name,
                        args: args,
                        result: result
                    )
                )
            } else {
                flushCalls()
                segments.append(.part(part))
            }
        }
        flushCalls()
        return segments
    }
}

struct MessageRow: View {
    let message: Message
    @State private var copied = false

    private var displayTexts: [String] {
        let partTexts = message.parts.compactMap { part -> String? in
            if case .text(let text) = part { return text }
            return nil
        }
        return MessageContentSanitizerLogic.displayTexts(
            partTexts: partTexts,
            fallback: message.content
        )
    }

    private var messageText: String {
        displayTexts.joined(separator: "\n\n")
    }

    private var reasoningText: String {
        MessageResponseMergeLogic.reasoningForDisplay(message)
    }

    private var showsThinkingSpoiler: Bool {
        message.role == .assistant
            && (!reasoningText.isEmpty || (message.isStreaming && !MessageDisplayLogic.hasVisibleAnswer(message)))
    }

    private var isThinkingInProgress: Bool {
        message.isStreaming && !MessageDisplayLogic.hasVisibleAnswer(message)
    }

    private var showsActionBar: Bool {
        MessageEditLogic.shouldShowActions(
            hasToolCalls: hasToolCalls,
            isStreaming: message.isStreaming,
            canEdit: MessageEditLogic.canEdit(message),
            displayText: messageText,
            hasAttachments: !(message.files ?? []).isEmpty
                || !MessageDisplayLogic.attachedImagesForDisplay(message).isEmpty
                || MessageDisplayLogic.hasImageParts(message)
        )
    }

    private var hasToolCalls: Bool {
        message.parts.contains {
            if case .toolCall = $0 { return true }
            return false
        }
    }

    private var isTrailing: Bool {
        MessageRowLayoutLogic.isTrailing(role: message.role)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isTrailing {
                // Telegram-style: user bubble hugs the trailing edge.
                Spacer(minLength: 40)

                VStack(alignment: .trailing, spacing: MessageRowLayoutLogic.actionBarSpacing) {
                    messageContent

                    if showsActionBar {
                        messageActions
                    }
                }
                .frame(maxWidth: MessageRowLayoutLogic.userBubbleMaxWidth, alignment: .trailing)

                Image(systemName: "person.circle").interfaceFont(size: 14).foregroundColor(Color.mimo.cyan).frame(width: 20)
            } else {
                if message.role == .assistant {
                    Image(systemName: "sparkle").interfaceFont(size: 14).foregroundColor(Color.mimo.brand).frame(width: 20)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if showsThinkingSpoiler {
                        ThinkingSpoilerView(
                            reasoning: reasoningText,
                            duration: message.reasoningDuration,
                            isThinking: isThinkingInProgress
                        )
                    }
                    messageContent

                    if showsActionBar {
                        HStack(spacing: 0) {
                            messageActions
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(width: 20)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var messageContent: some View {
        if !hasRenderableTextParts && !message.content.isEmpty {
            if let sanitized = MessageContentSanitizerLogic.sanitizedTextPart(message.content) {
                markdownBubble(sanitized)
            }
        }

        ForEach(contentSegments) { segment in
            switch segment {
            case .part(let part):
                partView(part)
            case .toolCalls(let calls):
                if calls.contains(where: isPendingQuestion) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(calls) { call in
                            toolCallPartView(call)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    SplitToolInspectorView(
                        steps: calls,
                        messageID: message.id,
                        isMessageStreaming: message.isStreaming
                    )
                }
            }
        }

        if let added = message.tokensAdded, let removed = message.tokensRemoved, added + removed > 0 {
            FileChangeSummaryRow(path: message.agentName ?? "Changes", additions: added, deletions: removed)
        }

        let legacyImages = MessageDisplayLogic.attachedImagesForDisplay(message)
        if !legacyImages.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(legacyImages) { img in
                        TappableChatImage(image: img, fillThumbnail: true)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var messageActions: some View {
        HStack(spacing: 2) {
            if !messageText.isEmpty {
                MessageActionButton(
                    icon: copied ? "checkmark" : "doc.on.doc",
                    tooltip: copied ? "Copied" : "Copy",
                    isActive: copied
                ) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(messageText, forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copied = false }
                    }
                }
            }

            if MessageEditLogic.canEdit(message) {
                MessageActionButton(icon: "pencil", tooltip: "Edit") {
                    NotificationCenter.default.post(
                        name: .editMessage,
                        object: nil,
                        userInfo: ["messageId": message.id]
                    )
                }

                if MessageEditLogic.canResend(message) {
                    MessageActionButton(
                        icon: message.role == .user ? "arrow.up.circle" : "arrow.counterclockwise",
                        tooltip: message.role == .user ? "Resend" : "Retry"
                    ) {
                        let name: Notification.Name = message.role == .user ? .resendMessage : .retryMessage
                        NotificationCenter.default.post(
                            name: name,
                            object: nil,
                            userInfo: ["messageId": message.id]
                        )
                    }
                }
            }
        }
        .padding(4)
        .background(Color.mimo.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.mimo.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func partView(_ part: MessagePartContent) -> some View {
        switch part {
        case .text(let text):
            if let sanitized = MessageContentSanitizerLogic.sanitizedTextPart(text) {
                markdownBubble(sanitized)
            }
        case .reasoning, .stepStart, .stepFinish:
            EmptyView()
        case .toolCall:
            EmptyView()
        case .image(let base64, let mimeType):
            if !base64.isEmpty {
                TappableChatImage(image: ClipboardImage(base64: base64, mimeType: mimeType))
            }
        }
    }

    @ViewBuilder
    private func toolCallPartView(_ call: ToolCallInspectorStep) -> some View {
        if PlanQuestionLogic.isQuestionTool(call.name), call.result == nil {
            let questions = PlanQuestionLogic.parseQuestions(from: call.args)
            if !questions.isEmpty {
                PlanQuestionCardView(questions: questions) { answers in
                    NotificationCenter.default.post(
                        name: .submitPlanQuestionAnswers,
                        object: nil,
                        userInfo: ["answers": answers]
                    )
                }
            } else {
                toolCallSpoiler(call)
            }
        } else {
            toolCallSpoiler(call)
        }
    }

    private func toolCallSpoiler(_ call: ToolCallInspectorStep) -> some View {
        SplitToolInspectorView(
            steps: [call],
            messageID: message.id,
            isMessageStreaming: message.isStreaming
        )
    }

    private func isPendingQuestion(_ call: ToolCallInspectorStep) -> Bool {
        PlanQuestionLogic.isQuestionTool(call.name) && call.result == nil
    }

    private var contentSegments: [MessageContentSegment] {
        MessageContentSegment.build(
            from: MessageDisplayLogic.chatDisplayParts(message.parts)
        )
    }

    private var hasRenderableTextParts: Bool {
        message.parts.contains { part in
            if case .text(let text) = part {
                return MessageContentSanitizerLogic.sanitizedTextPart(text) != nil
            }
            return false
        }
    }

    @ViewBuilder
    private func markdownBubble(_ text: String) -> some View {
        MarkdownText(text: text)
            .interfaceFont(size: 14)
            .foregroundColor(Color.mimo.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                message.role == .user
                    ? Color.mimo.brand.opacity(0.2)
                    : Color.mimo.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ThinkingSpoilerView: View {
    let reasoning: String
    let duration: TimeInterval?
    let isThinking: Bool
    @State private var isExpanded = false
    @State private var measuredContentHeight: CGFloat = 0

    private var canExpand: Bool {
        !reasoning.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                guard canExpand else { return }
                isExpanded.toggle()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .interfaceFont(size: 10, weight: .semibold)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .opacity(canExpand ? 1 : 0)
                        .frame(width: 10)

                    if isThinking {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "brain")
                            .interfaceFont(size: 11)
                    }

                    Text(L.t(AppLocalizationKey.locThinking))
                        .interfaceFont(size: 12, weight: .medium)

                    if let duration = duration, !isThinking {
                        Text(String(format: "%.1fs", duration))
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textMuted.opacity(0.6))
                    }

                    Spacer(minLength: 0)
                }
                .foregroundColor(Color.mimo.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canExpand && !isThinking)

            if canExpand {
                ScrollView {
                    MarkdownText(text: reasoning, fontSize: 12)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.top, 2)
                        .padding(.bottom, 10)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: SpoilerContentHeightKey.self,
                                    value: geo.size.height
                                )
                            }
                        )
                }
                .onPreferenceChange(SpoilerContentHeightKey.self) { measuredContentHeight = $0 }
                .frame(
                    height: SpoilerExpandLogic.contentHeight(
                        isExpanded: isExpanded,
                        measuredHeight: measuredContentHeight
                    ),
                    alignment: .top
                )
                .opacity(SpoilerExpandLogic.contentOpacity(isExpanded: isExpanded))
                .clipped()
                .allowsHitTesting(isExpanded)
            }
        }
        .background(Color.mimo.codeBg.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.mimo.border.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(SpoilerExpandLogic.animation, value: isExpanded)
    }
}

private struct SpoilerContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct SplitToolInspectorView: View {
    let steps: [ToolCallInspectorStep]
    let messageID: String
    let isMessageStreaming: Bool
    @State private var isExpanded = false
    @State private var selectedStepID: String?

    private var selectedStep: ToolCallInspectorStep? {
        steps.first(where: { $0.id == selectedStepID }) ?? steps.first
    }

    private var isComplete: Bool {
        ToolCallInspectorLogic.isComplete(steps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button(action: { isExpanded.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .interfaceFont(size: 10, weight: .semibold)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .frame(width: 10)
                        Image(systemName: "wrench.and.screwdriver")
                            .interfaceFont(size: 11)
                        Text(ToolCallInspectorLogic.headerTitle(for: steps))
                            .interfaceFont(size: 12, weight: .medium, design: .monospaced)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(Color.mimo.cyan)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 4)

                if isExpanded {
                    HStack(spacing: 4) {
                        Text(isComplete ? "Completed" : "Running")
                            .interfaceFont(size: 10, weight: .medium)
                        if isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .interfaceFont(size: 10)
                        } else {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.6)
                        }
                    }
                    .foregroundColor(isComplete ? Color.mimo.success : Color.mimo.cyan)

                    MessageActionButton(
                        icon: "stop.fill",
                        tooltip: "Stop"
                    ) {
                        NotificationCenter.default.post(name: .stopGeneration, object: nil)
                    }
                    .disabled(!isMessageStreaming)
                    .opacity(isMessageStreaming ? 1 : 0.45)

                    MessageActionButton(
                        icon: "arrow.counterclockwise",
                        tooltip: "Retry"
                    ) {
                        NotificationCenter.default.post(
                            name: .retryMessage,
                            object: nil,
                            userInfo: ["messageId": messageID]
                        )
                    }
                } else if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .interfaceFont(size: 10)
                        .foregroundColor(Color.mimo.success)
                } else {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)

            if isExpanded, let selectedStep {
                Divider()

                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            Button {
                                selectedStepID = step.id
                            } label: {
                                inspectorStepRow(
                                    number: index + 1,
                                    step: step,
                                    isSelected: step.id == selectedStep.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: 140, alignment: .top)
                    .frame(minHeight: 210, alignment: .top)
                    .background(Color.mimo.surface.opacity(0.55))

                    Divider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            detailBlock(
                                label: "Arguments",
                                value: argumentsText(for: selectedStep)
                            )

                            if let result = selectedStep.result, !result.isEmpty {
                                Divider()
                                detailBlock(
                                    label: "Result",
                                    value: ToolCallPresentationLogic.formattedResult(result)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                    }
                    .frame(maxWidth: .infinity, minHeight: 210, maxHeight: 380)
                }

                Divider()

                HStack(spacing: 10) {
                    Button {
                        isExpanded = false
                    } label: {
                        Label(L.t(AppLocalizationKey.locCollapse), systemImage: "chevron.up")
                            .interfaceFont(size: 11, weight: .medium)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.mimo.textSecondary)

                    Spacer(minLength: 0)

                    inspectorAction(icon: "doc.on.doc", title: L.t(AppLocalizationKey.locCopyAll)) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(
                            ToolCallInspectorLogic.copyText(for: steps),
                            forType: .string
                        )
                    }
                    inspectorAction(icon: "arrow.counterclockwise", title: L.t(AppLocalizationKey.locRetry)) {
                        NotificationCenter.default.post(
                            name: .retryMessage,
                            object: nil,
                            userInfo: ["messageId": messageID]
                        )
                    }
                    inspectorAction(icon: "pencil", title: L.t(AppLocalizationKey.locEdit)) {
                        NotificationCenter.default.post(
                            name: .editMessage,
                            object: nil,
                            userInfo: ["messageId": messageID]
                        )
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Color.mimo.surface.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mimo.codeBg)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.mimo.border.opacity(0.55), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .animation(SpoilerExpandLogic.animation, value: isExpanded)
        .onAppear {
            if selectedStepID == nil {
                selectedStepID = steps.first?.id
            }
        }
    }

    private func argumentsText(for step: ToolCallInspectorStep) -> String {
        ToolCallPresentationLogic.argumentSections(from: step.args)
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n\n")
    }

    private func inspectorStepRow(
        number: Int,
        step: ToolCallInspectorStep,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Text(String(number))
                .interfaceFont(size: 10, weight: .medium)
                .frame(width: 14)
            Text(step.name.capitalized)
                .interfaceFont(size: 11, weight: .medium)
                .lineLimit(1)
            Spacer(minLength: 4)
            if step.result == nil {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.55)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .interfaceFont(size: 9)
                    .foregroundColor(Color.mimo.success)
            }
        }
        .foregroundColor(Color.mimo.textSecondary)
        .padding(.horizontal, 8)
        .frame(height: 34)
        .background(isSelected ? Color.mimo.brand.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
    }

    private func detailBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .interfaceFont(size: 11, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)

            ScrollView(.horizontal) {
                Text(value)
                    .interfaceFont(size: 11, design: .monospaced)
                    .foregroundColor(Color.mimo.textSecondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inspectorAction(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

struct MessageActionButton: View {
    let icon: String
    let tooltip: String
    var isActive: Bool = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .interfaceFont(size: 11)
                .foregroundColor(isActive ? Color.mimo.success : Color.mimo.textMuted)
                .frame(width: 24, height: 24)
                .background(isHovering ? Color.mimo.surfaceHover : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(tooltip)
    }
}

struct FileChangeSummaryRow: View {
    let path: String
    let additions: Int
    let deletions: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .interfaceFont(size: 12)
                .foregroundColor(Color.mimo.textMuted)
            Text((path as NSString).lastPathComponent)
                .interfaceFont(size: 12, design: .monospaced)
                .foregroundColor(Color.mimo.textPrimary)
                .lineLimit(1)
            Spacer()
            Text("+\(additions)")
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.success)
            Text("-\(deletions)")
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.error)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.mimo.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
