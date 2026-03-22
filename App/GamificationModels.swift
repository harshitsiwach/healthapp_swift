import Foundation
import SwiftData

// MARK: - Wellness State
@Model
final class UserWellnessState {
    var id: UUID
    var currentScore: Double
    var nutritionScore: Double
    var activityScore: Double
    var recoveryScore: Double
    var habitScore: Double
    var consistencyScore: Double
    var lastUpdated: Date
    
    // XP & Leveling
    var totalXP: Int
    var currentLevel: Int
    
    // Streaks summary
    var currentStreakDays: Int
    var longestStreakDays: Int
    var lastStreakDate: String // YYYY-MM-DD
    
    init(
        id: UUID = UUID(),
        currentScore: Double = 50.0,
        nutritionScore: Double = 50.0,
        activityScore: Double = 50.0,
        recoveryScore: Double = 50.0,
        habitScore: Double = 50.0,
        consistencyScore: Double = 50.0,
        lastUpdated: Date = Date(),
        totalXP: Int = 0,
        currentLevel: Int = 1,
        currentStreakDays: Int = 0,
        longestStreakDays: Int = 0,
        lastStreakDate: String = ""
    ) {
        self.id = id
        self.currentScore = currentScore
        self.nutritionScore = nutritionScore
        self.activityScore = activityScore
        self.recoveryScore = recoveryScore
        self.habitScore = habitScore
        self.consistencyScore = consistencyScore
        self.lastUpdated = lastUpdated
        self.totalXP = totalXP
        self.currentLevel = currentLevel
        self.currentStreakDays = currentStreakDays
        self.longestStreakDays = longestStreakDays
        self.lastStreakDate = lastStreakDate
    }
}

// MARK: - XP Transaction
@Model
final class XPTransaction {
    var id: UUID
    var amount: Int
    var reason: String
    var timestamp: Date
    var type: String // e.g., "meal_logged", "workout_completed", "streak_bonus"
    
    init(id: UUID = UUID(), amount: Int, reason: String, timestamp: Date = Date(), type: String) {
        self.id = id
        self.amount = amount
        self.reason = reason
        self.timestamp = timestamp
        self.type = type
    }
}

// MARK: - Quest Models (Stubbed for Phase 28)
@Model
final class DailyQuest {
    var id: UUID
    var title: String
    var descriptionText: String
    var xpReward: Int
    var isCompleted: Bool
    var completedAt: Date?
    var targetDate: String // YYYY-MM-DD
    var type: String // e.g., "log_meals", "hydrate", "steps"
    var targetValue: Int
    var currentValue: Int
    
    init(id: UUID = UUID(), title: String, descriptionText: String, xpReward: Int, isCompleted: Bool = false, targetDate: String, type: String, targetValue: Int, currentValue: Int = 0) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.xpReward = xpReward
        self.isCompleted = isCompleted
        self.targetDate = targetDate
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
    }
}
