import Foundation
import SwiftData

/// Computes the WellnessScore (0-100) using weighted sub-scores
@MainActor
final class WellnessScoreEngine {
    static let shared = WellnessScoreEngine()
    
    private init() {}
    
    // MARK: - Weights
    
    private let nutritionWeight = 0.30
    private let activityWeight = 0.25
    private let recoveryWeight = 0.20
    private let habitWeight = 0.15
    private let consistencyWeight = 0.10
    
    // MARK: - Calculation
    
    func recomputeWellnessScore(context: ModelContext) {
        let descriptor = FetchDescriptor<UserWellnessState>()
        guard let state = try? context.fetch(descriptor).first else { return }
        
        // 1. Recompute Sub-scores based on recent data
        let nutrition = evaluateNutritionScore(context: context)
        let activity = evaluateActivityScore(context: context)
        let recovery = evaluateRecoveryScore(context: context)
        let habit = evaluateHabitScore(context: context)
        let consistency = evaluateConsistencyScore(for: state)
        
        // 2. Apply gentle smoothing/decay (in a real app, you'd compare against lastUpdated)
        // For this baseline, we just set the exact computed values
        state.nutritionScore = nutrition
        state.activityScore = activity
        state.recoveryScore = recovery
        state.habitScore = habit
        state.consistencyScore = consistency
        
        // 3. Compute final weighted score
        let totalScore = (nutrition * nutritionWeight) +
                         (activity * activityWeight) +
                         (recovery * recoveryWeight) +
                         (habit * habitWeight) +
                         (consistency * consistencyWeight)
        
        state.currentScore = min(100.0, max(0.0, totalScore))
        state.lastUpdated = Date()
        
        try? context.save()
    }
    
    // MARK: - Sub-score Evaluators
    
    private func evaluateNutritionScore(context: ModelContext) -> Double {
        // Look at the last 7 days of DailyLogs
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let descriptor = FetchDescriptor<DailyLog>()
        guard let logs = try? context.fetch(descriptor) else { return 50.0 }
        
        let recentLogs = logs.filter { log in
            if let logDate = formatter.date(from: log.date) {
                return logDate >= sevenDaysAgo
            }
            return false
        }
        
        if recentLogs.isEmpty { return 30.0 } // Decay baseline
        
        var dailyScores: [Double] = []
        
        // Group by day
        let grouped = Dictionary(grouping: recentLogs, by: { $0.date })
        
        for (_, dayLogs) in grouped {
            var dayScore = 0.0
            
            // Base points for logging any meal
            dayScore += 40.0
            
            // Bonus for logging multiple meals (Breakfast, Lunch, Dinner)
            let mealTypes = Set(dayLogs.map { $0.mealType })
            if mealTypes.count >= 3 {
                dayScore += 30.0
            }
            
            // Bonus for balanced macros (placeholder logic)
            // If total protein for the day > 50g, add points
            let dailyProtein = dayLogs.map { $0.protein }.reduce(0.0, +)
            if dailyProtein > 50.0 {
                dayScore += 30.0
            }
            
            dailyScores.append(min(100.0, dayScore))
        }
        
        // Average the last 7 days
        let avg = dailyScores.reduce(0.0, +) / Double(dailyScores.count)
        return avg
    }
    
    private func evaluateActivityScore(context: ModelContext) -> Double {
        // Integrate with HealthInsightsService, or use a baseline if permissions denied.
        // For now, returning a static good score as placeholder
        return 75.0
    }
    
    private func evaluateRecoveryScore(context: ModelContext) -> Double {
        // Integrate with HealthInsightsService for Sleep, or base on rest days.
        return 80.0
    }
    
    private func evaluateHabitScore(context: ModelContext) -> Double {
        // Based on water logging, medication, etc.
        return 70.0
    }
    
    private func evaluateConsistencyScore(for state: UserWellnessState) -> Double {
        // Based on streak
        let streak = Double(state.currentStreakDays)
        if streak >= 30 { return 100.0 }
        if streak >= 14 { return 85.0 }
        if streak >= 7 { return 70.0 }
        if streak >= 3 { return 50.0 }
        return 30.0
    }
}
