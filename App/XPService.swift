import Foundation
import SwiftData

/// Handles the XP and Leveling mechanics (Seed -> Legendary)
@MainActor
final class XPService {
    static let shared = XPService()
    
    private init() {}
    
    // MARK: - Level Thresholds
    
    private let levelThresholds: [Int] = [
        0,      // Level 1: Seed
        100,    // Level 2: Seed II
        300,    // Level 3: Seed III
        600,    // Level 4: Active I
        1000,   // Level 5: Active II
        1500,   // Level 6: Active III
        2200,   // Level 7: Balanced I
        3000,   // Level 8: Balanced II
        4000,   // Level 9: Balanced III
        5500,   // Level 10: Strong I
        7500,   // Level 11: Strong II
        10000,  // Level 12: Strong III
        15000,  // Level 13: Elite I
        25000,  // Level 14: Elite II
        50000   // Level 15: Legendary
    ]
    
    func getRankName(for level: Int) -> String {
        switch level {
        case 1...3: return "Seed"
        case 4...6: return "Active"
        case 7...9: return "Balanced"
        case 10...12: return "Strong"
        case 13...14: return "Elite"
        case 15...: return "Legendary"
        default: return "Seed"
        }
    }
    
    func getNextLevelXP(currentLevel: Int) -> Int {
        guard currentLevel < levelThresholds.count else {
            return levelThresholds.last ?? 50000 // Max level cap reference
        }
        return levelThresholds[currentLevel]
    }
    
    // MARK: - XP Awards
    
    struct XPAward {
        static let mealLogged = 10
        static let balancedMeal = 20
        static let hydrationGoal = 15
        static let stepGoal = 25
        static let workoutCompleted = 40
        static let sleepTarget = 25
        static let dailyQuest = 30
        static let weeklyQuest = 80
        static let streak7Days = 50
    }
    
    func awardXP(amount: Int, reason: String, type: String, context: ModelContext) {
        // Fetch or create wellness state
        let descriptor = FetchDescriptor<UserWellnessState>()
        let state: UserWellnessState
        if let existing = try? context.fetch(descriptor).first {
            state = existing
        } else {
            state = UserWellnessState()
            context.insert(state)
        }
        
        // Add transaction
        let transaction = XPTransaction(amount: amount, reason: reason, type: type)
        context.insert(transaction)
        
        // Update state
        state.totalXP += amount
        
        // Check for level up
        let newLevel = calculateLevel(from: state.totalXP)
        if newLevel > state.currentLevel {
            state.currentLevel = newLevel
            // Trigger level up celebration UI if needed
            NotificationCenter.default.post(name: NSNotification.Name("UserLeveledUp"), object: nil, userInfo: ["newLevel": newLevel])
        }
        
        try? context.save()
    }
    
    private func calculateLevel(from xp: Int) -> Int {
        for (index, threshold) in levelThresholds.enumerated().reversed() {
            if xp >= threshold {
                return index + 1 // Levels are 1-indexed
            }
        }
        return 1
    }
}
