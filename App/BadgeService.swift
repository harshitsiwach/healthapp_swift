import Foundation
import SwiftData

@Model
final class Badge {
    var id: UUID
    var name: String
    var descriptionText: String
    var systemImageName: String
    var unlockedAt: Date?
    var category: String // "streak", "activity", "nutrition", "community"
    
    init(id: UUID = UUID(), name: String, descriptionText: String, systemImageName: String, unlockedAt: Date? = nil, category: String) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.systemImageName = systemImageName
        self.unlockedAt = unlockedAt
        self.category = category
    }
}

/// Handles unlocking conditions for community and milestone badges
@MainActor
final class BadgeService {
    static let shared = BadgeService()
    
    private init() {}
    
    func initializeBadgesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Badge>()
        if (try? context.fetch(descriptor))?.isEmpty == true {
            let initialBadges = [
                Badge(name: "First Steps", descriptionText: "Log your first meal.", systemImageName: "leaf.fill", category: "nutrition"),
                Badge(name: "Consistent", descriptionText: "Hit a 7 day streak.", systemImageName: "flame.fill", category: "streak"),
                Badge(name: "Balanced Eaten", descriptionText: "Log 10 balanced meals.", systemImageName: "chart.pie.fill", category: "nutrition"),
                Badge(name: "Routine Creator", descriptionText: "Publish your first public routine.", systemImageName: "doc.text.image.fill", category: "community")
            ]
            for b in initialBadges { context.insert(b) }
            try? context.save()
        }
    }
    
    func unlockBadge(name: String, context: ModelContext) {
        // Find badge by name
        let descriptor = FetchDescriptor<Badge>()
        guard let allBadges = try? context.fetch(descriptor) else { return }
        
        if let badge = allBadges.first(where: { $0.name == name && $0.unlockedAt == nil }) {
            badge.unlockedAt = Date()
            XPService.shared.awardXP(amount: 100, reason: "Badge Unlocked: \(name)", type: "badge", context: context)
            NotificationCenter.default.post(name: NSNotification.Name("BadgeUnlocked"), object: nil, userInfo: ["badge": badge.name])
            try? context.save()
        }
    }
}
