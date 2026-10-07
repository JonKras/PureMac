import SwiftUI

struct ScanRecommendation: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let actionLabel: LocalizedStringKey
    let action: RecommendationAction

    enum RecommendationAction: Equatable {
        case cleanCategory(CleaningCategory)
        case startSmartScan
        case openSystemSettings
    }
}

extension ScanRecommendation {
    static func build(from results: [CategoryResult], diskInfo: DiskInfo, lastCleanedDate: Date?) -> [ScanRecommendation] {
        var recommendations: [ScanRecommendation] = []

        // 1. Largest junk category (top result with > 10 MB)
        if let top = results.sorted(by: { $0.totalSize > $1.totalSize }).first, top.totalSize > 10 * 1024 * 1024 {
            let sizeStr = ByteCountFormatter.string(fromByteCount: top.totalSize, countStyle: .file)
            recommendations.append(ScanRecommendation(
                icon: top.category.icon,
                tint: top.category.color,
                title: LocalizedStringKey(top.category.rawValue),
                detail: "Free up \(sizeStr)",
                actionLabel: "Clean now",
                action: .cleanCategory(top.category)
            ))
        }

        // 2. Developer caches (Xcode / Brew / Node / Docker) — combined hint if any present
        let devCategories: [CleaningCategory] = [.xcodeJunk, .brewCache, .nodeCache, .dockerCache]
        let devResults = results.filter { devCategories.contains($0.category) && $0.totalSize > 50 * 1024 * 1024 }
        if !devResults.isEmpty, recommendations.first?.action != .cleanCategory(devResults[0].category) {
            let best = devResults.sorted { $0.totalSize > $1.totalSize }.first!
            recommendations.append(ScanRecommendation(
                icon: "hammer.fill",
                tint: .cyan,
                title: "Developer cache detected",
                detail: "Xcode, Brew or Node caches found. Good candidates for cleanup.",
                actionLabel: "Clean now",
                action: .cleanCategory(best.category)
            ))
        }

        // 3. Storage almost full (> 85 %)
        if diskInfo.totalSpace > 0 {
            let usedPercent = Double(diskInfo.usedSpace) / Double(diskInfo.totalSpace)
            if usedPercent > 0.85 {
                recommendations.append(ScanRecommendation(
                    icon: "internaldrive.fill",
                    tint: .orange,
                    title: "Storage is almost full",
                    detail: "Your disk is over 85%% used. Clean up soon.",
                    actionLabel: "Run Smart Scan",
                    action: .startSmartScan
                ))
            }
        }

        // 4. Last clean > 30 days ago (or never)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        if results.isEmpty || (lastCleanedDate.map { $0 < thirtyDaysAgo } ?? true) {
            if recommendations.count < 3 {
                recommendations.append(ScanRecommendation(
                    icon: "calendar.badge.exclamationmark",
                    tint: .yellow,
                    title: "Last cleaned over 30 days ago",
                    detail: "A full cleanup is overdue.",
                    actionLabel: "Run Smart Scan",
                    action: .startSmartScan
                ))
            }
        }

        return Array(recommendations.prefix(3))
    }
}
