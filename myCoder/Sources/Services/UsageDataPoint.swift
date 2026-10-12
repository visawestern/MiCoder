import Foundation

/// One usage data point read from a database (plan Раздел 10 Блок 2 п.13-14).
/// Cost is nil when the provider supplies no trustworthy price.
struct UsageDataPoint: Equatable {
    let timestamp: Date
    let model: String
    let provider: String
    let promptTokens: Int
    let completionTokens: Int
    let costUSD: Double?

    init(timestamp: Date, model: String, provider: String,
         promptTokens: Int, completionTokens: Int, costUSD: Double?) {
        self.timestamp = timestamp
        self.model = model
        self.provider = provider
        self.promptTokens = max(0, promptTokens)
        self.completionTokens = max(0, completionTokens)
        self.costUSD = UsageCostSafety.sanitized(costUSD)
    }

    var totalTokens: Int { promptTokens + completionTokens }
}
