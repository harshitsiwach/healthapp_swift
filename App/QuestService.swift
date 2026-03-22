import Foundation
import SwiftData

/// Manages Daily and Weekly Missions/Quests for the user
@MainActor
final class QuestService {
    static let shared = QuestService()
    
    private init() {}
    
    /// Call this daily (e.g., app launch) to generate fresh quests for today
    func generateDailyQuests(context: ModelContext) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        let descriptor = FetchDescriptor<DailyQuest>(predicate: #Predicate { $0.targetDate == todayStr })
        let currentQuests = (try? context.fetch(descriptor)) ?? []
        
        if currentQuests.isEmpty {
            // Generate standard generic quests
            let quests = [
                DailyQuest(title: "Log 3 Meals", descriptionText: "Add 3 meals to your diary today.", xpReward: 30, targetDate: todayStr, type: "log_meals", targetValue: 3),
                DailyQuest(title: "Hit 8,000 Steps", descriptionText: "Get moving and hit your daily step goal.", xpReward: 25, targetDate: todayStr, type: "steps", targetValue: 8000),
                DailyQuest(title: "Hydration Hero", descriptionText: "Log all your water today.", xpReward: 15, targetDate: todayStr, type: "hydrate", targetValue: 1) // 1 means boolean complete
            ]
            
            for q in quests {
                context.insert(q)
            }
            try? context.save()
        }
    }
    
    /// Evaluates quest progress based on recent actions
    func evaluateProgress(type: String, amount: Int, context: ModelContext) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        let descriptor = FetchDescriptor<DailyQuest>(predicate: #Predicate {
            $0.targetDate == todayStr && $0.type == type && $0.isCompleted == false
        })
        
        guard let activeQuests = try? context.fetch(descriptor) else { return }
        
        for quest in activeQuests {
            quest.currentValue += amount
            if quest.currentValue >= quest.targetValue {
                quest.isCompleted = true
                quest.completedAt = Date()
                XPService.shared.awardXP(amount: quest.xpReward, reason: "Quest Completed: \(quest.title)", type: "quest", context: context)
                NotificationCenter.default.post(name: NSNotification.Name("QuestCompleted"), object: nil, userInfo: ["title": quest.title])
            }
        }
        
        try? context.save()
    }
}
