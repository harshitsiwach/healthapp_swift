import Foundation
import SwiftData

/// Central orchestrator combining Score, XP, and Streaks.
/// Call `GamificationEngine.shared.processDailyActivity()` whenever a meaningful action occurs.
@MainActor
final class GamificationEngine {
    static let shared = GamificationEngine()
    
    private init() {}
    
    func processDailyActivity(actionType: ActivityActionType, context: ModelContext) {
        // 1. Update Streak
        StreakService.shared.recordActivity(context: context)
        
        // 2. Award XP
        switch actionType {
        case .mealLogged(let isBalanced):
            let amount = isBalanced ? XPService.XPAward.balancedMeal : XPService.XPAward.mealLogged
            XPService.shared.awardXP(amount: amount, reason: isBalanced ? "Balanced Meal Logged" : "Meal Logged", type: "meal", context: context)
        case .workoutCompleted:
            XPService.shared.awardXP(amount: XPService.XPAward.workoutCompleted, reason: "Workout Completed", type: "workout", context: context)
        case .stepGoalMet:
            XPService.shared.awardXP(amount: XPService.XPAward.stepGoal, reason: "Step Goal Met", type: "activity", context: context)
        case .hydrationGoalMet:
            XPService.shared.awardXP(amount: XPService.XPAward.hydrationGoal, reason: "Hydration Goal Met", type: "habit", context: context)
        case .sleepTargetMet:
            XPService.shared.awardXP(amount: XPService.XPAward.sleepTarget, reason: "Sleep Target Met", type: "recovery", context: context)
        }
        
        // 3. Recompute Wellness Score
        WellnessScoreEngine.shared.recomputeWellnessScore(context: context)
        
        // 4. (Future) Evaluate Quest Completions
        // QuestService.shared.evaluateQuests(context: context)
        
        // 5. (Future) Check Badge Unlocks
        // BadgeService.shared.checkBadges(context: context)
        
        try? context.save()
    }
}

enum ActivityActionType {
    case mealLogged(isBalanced: Bool)
    case workoutCompleted
    case stepGoalMet
    case hydrationGoalMet
    case sleepTargetMet
}
