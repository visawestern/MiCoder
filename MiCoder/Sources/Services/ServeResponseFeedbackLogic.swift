enum ServeResponseFeedbackLogic {
    static func failureMessage(text: String,
                               reasoning: String,
                               hasToolActivity: Bool) -> String? {
        guard ProviderResponseValidationLogic.shouldReportEmptyCompletion(
            text: text,
            reasoning: reasoning,
            hasToolActivity: hasToolActivity
        ) else { return nil }
        return ProviderResponseValidationLogic.emptyCompletionMessage
    }
}
