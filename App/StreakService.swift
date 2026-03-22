import Foundation
import SwiftData

/// Manages daily streaks including milestone bonuses and grace periods.
@MainActor
final class StreakService {
    static let shared = StreakService()
    
    private init() {}
    
    /// Called when the user completes a core daily habit (e.g., logging a meal)
    func recordActivity(context: ModelContext) {
        let descriptor = FetchDescriptor<UserWellnessState>()
        let state: UserWellnessState
        if let existing = try? context.fetch(descriptor).first {
            state = existing
        } else {
            state = UserWellnessState()
            context.insert(state)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        
        // If already recorded today, do nothing array to streak sum
        if state.lastStreakDate == today {
            return
        }
        
        if state.lastStreakDate == yesterday {
            // Continued streak
            state.currentStreakDays += 1
        } else {
            // Broken streak, reset
            // Could add Grace Period/Skip Token logic here in the future
            state.currentStreakDays = 1
        }
        
        state.lastStreakDate = today
        
        if state.currentStreakDays > state.longestStreakDays {
            state.longestStreakDays = state.currentStreakDays
        }
        
        // Award XP for milestone streaks
        checkStreakMilestones(streak: state.currentStreakDays, context: context)
        
        try? context.save()
    }
    
    private func checkStreakMilestones(streak: Int, context: ModelContext) {
        if streak == 3 {
             XPService.shared.awardXP(amount: 25, reason: "3 Day Streak!", type: "streak", context: context)
        } else if streak == 7 {
             XPService.shared.awardXP(amount: 50, reason: "7 Day Streak!", type: "streak", context: context)
        } else if streak == 14 {
             XPService.shared.awardXP(amount: 100, reason: "14 Day Streak!", type: "streak", context: context)
        } else if streak == 30 {
             XPService.shared.awardXP(amount: 300, reason: "30 Day Streak (Epic!)", type: "streak", context: context)
        }
    }
}
