import Foundation
import SwiftData

/// Allows users to publish and copy routines (e.g., wake windows, meal schedules)
@MainActor
final class RoutineTemplateService {
    static let shared = RoutineTemplateService()
    
    private init() {}
    
    func publishRoutine(context: ModelContext) {
        // Create a basic routine from user's current settings
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? context.fetch(descriptor).first else { return }
        let author = profile.name
        let hydration = profile.waterGoalLiters
        
        let routine = RoutineTemplate(
            authorName: author,
            title: "\(author)'s Daily Flow",
            descriptionText: "My standard healthy balanced routine.",
            wakeTime: "07:00",
            sleepTime: "23:00",
            hydrationGoalLiters: hydration,
            stepGoal: 10000,
            mealCadence: 3
        )
        
        context.insert(routine)
        try? context.save()
    }
    
    func copyRoutine(_ routine: RoutineTemplate, context: ModelContext) {
        // Assume applying these settings to the user's profile
        routine.copyCount += 1
        routine.isUserActiveRoutine = true
        
        // Let's pretend we apply it
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(descriptor).first {
             profile.waterGoalLiters = routine.hydrationGoalLiters
             // Other updates...
        }
        
        try? context.save()
    }
}
