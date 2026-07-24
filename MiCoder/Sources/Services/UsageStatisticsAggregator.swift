import Foundation

/// One usage data point read from the DB (plan Раздел 10 Блок 2 п.13-14).
/// Sourced from existing `prompt_tokens`/`completion_tokens`/`cost_usd` columns
/// tagged with model+provider — no fabricated numbers.
struct UsageDataPoint: Equatable {
    let timestamp: Date
    let model: String
    let provider: String
    let promptTokens: Int
    let completionTokens: Int
    /// nil for local providers (Ollama/mimoCLI) where cost is not applicable.
    let costUSD: Double?

    var totalTokens: Int { promptTokens + completionTokens }
}

/// Per-model (or per-provider) aggregate (plan Блок 2 п.16/п.38).
struct UsageAggregate: Equatable {
    let key: String              // model id or provider id
    var messageCount: Int
    var promptTokens: Int
    var completionTokens: Int
    var costUSD: Double?         // nil when no data point had a cost (local-only)

    var totalTokens: Int { promptTokens + completionTokens }
}

/// A time window filter (plan Блок 2 п.15).
struct UsageDateRange: Equatable {
    let start: Date
    let end: Date

    static func lastDays(_ days: Int, now: Date = Date()) -> UsageDateRange {
        UsageDateRange(start: now.addingTimeInterval(-Double(days) * 86400), end: now)
    }

    func contains(_ date: Date) -> Bool { date >= start && date <= end }
}

/// Pure aggregation of usage statistics from real DB rows (plan Раздел 10 Блок 2).
/// No hardcoded "—" or "$0.00" — cost is nil (N/A) when inapplicable.
enum UsageStatisticsAggregator {

    /// Filter points to a date range (plan Блок 2 п.15).
    static func filter(_ points: [UsageDataPoint], range: UsageDateRange?) -> [UsageDataPoint] {
        guard let range = range else { return points }
        return points.filter { range.contains($0.timestamp) }
    }

    /// Normalize a model id so `gpt-4o-2024-08-06` and `gpt-4o` aggregate together
    /// (plan Блок 4 п.49). Strips a trailing date/snapshot suffix.
    static func normalizeModelName(_ model: String) -> String {
        // Remove a trailing "-YYYY-MM-DD" or "-YYYYMMDD" snapshot suffix.
        let patterns = ["-\\d{4}-\\d{2}-\\d{2}$", "-\\d{8}$"]
        var result = model
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
            }
        }
        return result
    }

    /// Aggregate by model (normalized) (plan Блок 2 п.16).
    static func aggregateByModel(_ points: [UsageDataPoint], normalize: Bool = true) -> [UsageAggregate] {
        aggregate(points) { normalize ? normalizeModelName($0.model) : $0.model }
    }

    /// Aggregate by provider (plan Блок 4 п.38).
    static func aggregateByProvider(_ points: [UsageDataPoint]) -> [UsageAggregate] {
        aggregate(points) { $0.provider }
    }

    private static func aggregate(_ points: [UsageDataPoint], key: (UsageDataPoint) -> String) -> [UsageAggregate] {
        var map: [String: UsageAggregate] = [:]
        for p in points {
            let k = key(p)
            var agg = map[k] ?? UsageAggregate(key: k, messageCount: 0, promptTokens: 0, completionTokens: 0, costUSD: nil)
            agg.messageCount += 1
            agg.promptTokens += p.promptTokens
            agg.completionTokens += p.completionTokens
            if let cost = p.costUSD {
                agg.costUSD = (agg.costUSD ?? 0) + cost
            }
            map[k] = agg
        }
        // Sort by total tokens desc for a stable, meaningful order.
        return map.values.sorted { $0.totalTokens > $1.totalTokens }
    }

    /// The most-used model by token volume over the period (plan Блок 2 п.19).
    /// This is BY ACTUAL USAGE, not the currently-selected model.
    static func favoriteModel(_ points: [UsageDataPoint]) -> String? {
        aggregateByModel(points).first?.key
    }

    /// Number of unique calendar days with at least one message (plan Блок 2 п.20).
    /// Correctly counts distinct days, not reused session count.
    static func activeDays(_ points: [UsageDataPoint], calendar: Calendar = .current) -> Int {
        let days = Set(points.map { calendar.startOfDay(for: $0.timestamp) })
        return days.count
    }

    /// Total tokens/cost across all points (cost nil if no point had cost).
    static func totals(_ points: [UsageDataPoint]) -> (tokens: Int, cost: Double?) {
        let tokens = points.reduce(0) { $0 + $1.totalTokens }
        let costs = points.compactMap { $0.costUSD }
        return (tokens, costs.isEmpty ? nil : costs.reduce(0, +))
    }

    /// Cost display: "N/A" for local providers, formatted USD otherwise
    /// (plan Блок 2 п.22 — no misleading "$0.00").
    static func costLabel(_ cost: Double?) -> String {
        guard let cost = cost else { return "N/A" }
        return String(format: "$%.2f", cost)
    }
}
