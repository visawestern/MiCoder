import Foundation

// MARK: - Routes and transport

/// Routes the spec planner can talk to directly. Chat-only transports (web,
/// ACP, the MiMo serve session API) are deliberately not listed: the wizard
/// must not create visible chat sessions for its internal turns.
enum SpecPlannerRoute: Equatable {
    case openAICompatible(baseURL: String, apiKey: String?, model: String)
    case autoFree(model: String)

    init?(sendRoute: SendRoute, model: String) {
        switch sendRoute {
        case .openAICompatible(let baseURL, let apiKey, let routeModel):
            self = .openAICompatible(
                baseURL: baseURL,
                apiKey: apiKey,
                model: model.isEmpty ? routeModel : model
            )
        case .autoFree:
            self = .autoFree(model: model)
        case .mimoServe, .acp, .openCodeServe, .web, .none:
            return nil
        }
    }
}

struct SpecCompletionRequest: Equatable {
    let route: SpecPlannerRoute
    let messages: [DirectChatMessage]
}

protocol SpecCompletionProviding {
    func complete(_ request: SpecCompletionRequest) async throws -> String
}

struct LiveSpecCompletionProvider: SpecCompletionProviding {
    func complete(_ request: SpecCompletionRequest) async throws -> String {
        switch request.route {
        case .openAICompatible(let baseURL, let apiKey, let model):
            let result = try await DirectChatClient.send(
                baseURL: baseURL,
                apiKey: apiKey,
                model: model,
                messages: request.messages
            )
            return result.content

        case .autoFree(let model):
            let messages = request.messages.map {
                MiCoderAutoFreeClient.Message(role: $0.role, content: $0.content)
            }
            var text = ""
            for try await event in MiCoderAutoFreeClient.shared.chatCompletion(
                model: model,
                messages: messages,
                stream: false
            ) {
                if case .content(let chunk) = event {
                    text += chunk
                }
            }
            return text
        }
    }
}

// MARK: - Service

struct SpecPlannerTurn: Equatable {
    let role: String
    let content: String
}

enum SpecPlannerServiceError: Error, Equatable, LocalizedError {
    case emptyResponse
    case emptySpecification
    case unsupportedRoute

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "The planner returned an empty response"
        case .emptySpecification:
            return "The planner returned an empty specification"
        case .unsupportedRoute:
            return "The selected provider cannot run the spec planner. Choose an OpenAI-compatible, local or free model."
        }
    }
}

struct SpecPlannerService {
    let provider: SpecCompletionProviding

    init(provider: SpecCompletionProviding = LiveSpecCompletionProvider()) {
        self.provider = provider
    }

    func nextInterviewQuestion(projectName: String,
                               brief: SpecWizardDraft,
                               turns: [SpecPlannerTurn],
                               route: SpecPlannerRoute) async throws -> SpecInterviewQuestion {
        let raw = try await complete(
            route: route,
            messages: SpecPlannerPrompts.interviewMessages(
                projectName: projectName,
                brief: brief,
                turns: turns
            )
        )
        return try SpecInterviewLogic.decode(raw)
    }

    func generateSpecification(projectName: String,
                               brief: SpecWizardDraft,
                               turns: [SpecPlannerTurn],
                               route: SpecPlannerRoute) async throws -> String {
        let raw = try await complete(
            route: route,
            messages: SpecPlannerPrompts.specificationMessages(
                projectName: projectName,
                brief: brief,
                turns: turns
            )
        )
        let spec = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SpecRevisionLogic.isValid(content: spec) else {
            throw SpecPlannerServiceError.emptySpecification
        }
        return spec
    }

    func generateDecomposition(projectName: String,
                               brief: SpecWizardDraft,
                               specification: String,
                               route: SpecPlannerRoute) async throws -> SpecDecomposition {
        let raw = try await complete(
            route: route,
            messages: SpecPlannerPrompts.decompositionMessages(
                projectName: projectName,
                brief: brief,
                specification: specification
            )
        )
        return try SpecDecompositionLogic.decode(raw)
    }

    private func complete(route: SpecPlannerRoute,
                          messages: [DirectChatMessage]) async throws -> String {
        let raw = try await provider.complete(
            SpecCompletionRequest(route: route, messages: messages)
        )
        guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpecPlannerServiceError.emptyResponse
        }
        return raw
    }
}

// MARK: - Prompts

enum SpecPlannerPrompts {
    static func interviewMessages(projectName: String,
                                  brief: SpecWizardDraft,
                                  turns: [SpecPlannerTurn]) -> [DirectChatMessage] {
        let system = """
        You are the specification planner for a software project.
        Ask exactly ONE question at a time to remove ambiguity from the brief.
        Prefer concrete, answerable questions. Do not write code and do not invent requirements.

        Return ONLY a JSON object, with no prose around it:
        {"id":"short_stable_id","question":"...","suggested_answers":["..."],"done":false}
        suggested_answers must contain 1-5 short options, or be empty.
        When the brief and answers are sufficient, return:
        {"id":"final","done":true,"summary":"one sentence describing what is clear"}
        """
        return [
            DirectChatMessage(role: "system", content: system),
            DirectChatMessage(role: "user", content: interviewUserText(
                projectName: projectName,
                brief: brief,
                turns: turns
            ))
        ]
    }

    static func specificationMessages(projectName: String,
                                      brief: SpecWizardDraft,
                                      turns: [SpecPlannerTurn]) -> [DirectChatMessage] {
        let system = """
        You write a precise, testable technical specification in Markdown.
        Use only the brief and the interview answers. Include: goal, scope, non-goals,
        functional requirements, constraints and acceptance criteria.
        Do not write implementation code and do not add requirements that were not discussed.
        Return the Markdown document only.
        """
        return [
            DirectChatMessage(role: "system", content: system),
            DirectChatMessage(role: "user", content: interviewUserText(
                projectName: projectName,
                brief: brief,
                turns: turns
            ))
        ]
    }

    static func decompositionMessages(projectName: String,
                                      brief: SpecWizardDraft,
                                      specification: String) -> [DirectChatMessage] {
        let system = """
        Split the specification into atomic implementation nodes. Every node must be
        independently verifiable and small enough for one focused coding session.
        Use stable keys (N1, N2, ...), explicit dependencies and concrete acceptance criteria.
        The dependency graph must be acyclic. Return ONLY JSON:
        {"nodes":[{"key":"N1","title":"...","description":"...","kind":"task",
        "acceptance_criteria":["..."],"depends_on":[]}]}
        Do not add prose or Markdown fences.
        """
        let user = """
        Project: \(projectName)
        Goal: \(brief.goal)
        Stack: \(brief.stack)
        Constraints: \(brief.constraints)

        Specification:
        \(specification)
        """
        return [
            DirectChatMessage(role: "system", content: system),
            DirectChatMessage(role: "user", content: user)
        ]
    }

    private static func interviewUserText(projectName: String,
                                          brief: SpecWizardDraft,
                                          turns: [SpecPlannerTurn]) -> String {
        var lines = [
            "Project: \(projectName)",
            "Goal: \(brief.goal)",
            "Stack: \(brief.stack)",
            "Constraints: \(brief.constraints)"
        ]
        if !turns.isEmpty {
            lines.append("")
            lines.append("Interview so far:")
            for turn in turns {
                lines.append("\(turn.role): \(turn.content)")
            }
        }
        return lines.joined(separator: "\n")
    }
}
