import SwiftUI

struct RecommendationsView: View {
    let recommendations: [ScanRecommendation]
    let onAction: (ScanRecommendation.RecommendationAction) -> Void

    var body: some View {
        CardSurface(padding: 0, elevation: .flat) {
            VStack(spacing: 0) {
                ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, rec in
                    RecommendationRow(recommendation: rec) {
                        onAction(rec.action)
                    }
                    if index < recommendations.count - 1 {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
        }
    }
}

private struct RecommendationRow: View {
    let recommendation: ScanRecommendation
    let onTap: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 14) {
            IconTile(
                systemName: recommendation.icon,
                tint: recommendation.tint,
                size: 36,
                corner: 9
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.system(size: 13, weight: .medium))
                Text(recommendation.detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                onTap()
            } label: {
                Text(recommendation.actionLabel)
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(recommendation.tint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(hovering ? Color.primary.opacity(0.04) : Color.clear)
        .onHover { hovering = $0 }
        .contentShape(Rectangle())
    }
}
