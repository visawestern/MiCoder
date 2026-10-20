import SwiftUI

/// Small ring + percentage that shows how much of the model's context window
/// the current chat occupies (measured over the model-bound history, so it
/// drops immediately after `/compact`). Hovering reveals exact tokens.
struct ContextUsageBadge: View {
    let usage: ContextUsage

    private var tint: Color {
        if usage.ratio >= ContextUsageLogic.compactThreshold { return Color.mimo.error }
        if usage.ratio >= 0.75 { return Color.mimo.warning }
        return Color.mimo.cyan
    }

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(Color.mimo.textMuted.opacity(0.22), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: max(0.02, usage.ratio))
                    .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 12, height: 12)

            Text(ContextUsageLogic.badgeText(usage))
                .interfaceFont(size: 10)
                .foregroundColor(usage.ratio >= 0.75 ? tint : Color.mimo.textMuted)
        }
        .help(ContextUsageLogic.detailText(usage))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ContextUsageLogic.detailText(usage))
    }
}
