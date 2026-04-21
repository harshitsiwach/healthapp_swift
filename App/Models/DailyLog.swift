import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID
    var date: String // YYYY-MM-DD
    var foodName: String?
    var estimatedCalories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var goalCompleted: Int? // nil = not answered, 1 = yes, 0 = no
    var imageUri: String?
    
    // Health metrics
    var steps: Int?
    var sleepHours: Int?
    var sleepMinutes: Int?
    var heartRate: Int?
    var waterML: Int?
    var hrvMs: Double? // Heart Rate Variability in milliseconds
    var stressLevel: Int? // 1-10 scale
    
    init(
        date: String,
        foodName: String? = nil,
        estimatedCalories: Int = 0,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        goalCompleted: Int? = nil,
        imageUri: String? = nil,
        steps: Int? = nil,
        sleepHours: Int? = nil,
        sleepMinutes: Int? = nil,
        heartRate: Int? = nil,
        waterML: Int? = nil,
        hrvMs: Double? = nil,
        stressLevel: Int? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.foodName = foodName
        self.estimatedCalories = estimatedCalories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.goalCompleted = goalCompleted
        self.imageUri = imageUri
        self.steps = steps
        self.sleepHours = sleepHours
        self.sleepMinutes = sleepMinutes
        self.heartRate = heartRate
        self.waterML = waterML
        self.hrvMs = hrvMs
        self.stressLevel = stressLevel
    }
}
