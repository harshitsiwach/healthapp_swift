import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var gender: String
    var dob: Date
    var heightCm: Double
    var weightKg: Double
    var workoutsPerWeek: Int
    var goal: String // "lose", "maintain", "gain"
    var dietaryPreference: String // "vegetarian", "vegan", "eggetarian", "non-vegetarian"
    var calculatedDailyCalories: Int
    var calculatedDailyCarbs: Int
    var calculatedDailyProtein: Int
    var calculatedDailyFats: Int
    var healthScore: Int
    var streakCount: Int
    var lastOpenedDate: String // YYYY-MM-DD
    var notificationTime: String // HH:mm
    var name: String
    var waterGoalLiters: Double
    var stepGoal: Int
    
    init(
        name: String = "User",
        waterGoalLiters: Double = 2.5,
        stepGoal: Int = 10000,
        gender: String = "Male",
        dob: Date = Date(),
        heightCm: Double = 170,
        weightKg: Double = 70,
        workoutsPerWeek: Int = 3,
        goal: String = "maintain",
        dietaryPreference: String = "vegetarian",
        calculatedDailyCalories: Int = 2000,
        calculatedDailyCarbs: Int = 250,
        calculatedDailyProtein: Int = 125,
        calculatedDailyFats: Int = 56,
        healthScore: Int = 80,
        streakCount: Int = 1,
        lastOpenedDate: String = "",
        notificationTime: String = "20:00"
    ) {
        self.id = UUID()
        self.gender = gender
        self.dob = dob
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.workoutsPerWeek = workoutsPerWeek
        self.goal = goal
        self.dietaryPreference = dietaryPreference
        self.calculatedDailyCalories = calculatedDailyCalories
        self.calculatedDailyCarbs = calculatedDailyCarbs
        self.calculatedDailyProtein = calculatedDailyProtein
        self.calculatedDailyFats = calculatedDailyFats
        self.healthScore = healthScore
        self.streakCount = streakCount
        self.lastOpenedDate = lastOpenedDate
        self.notificationTime = notificationTime
        self.name = name
        self.waterGoalLiters = waterGoalLiters
        self.stepGoal = stepGoal
    }
}
