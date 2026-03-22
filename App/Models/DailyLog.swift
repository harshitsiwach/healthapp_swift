import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: String // YYYY-MM-DD
    var foodName: String?
    var estimatedCalories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var goalCompleted: Int? // nil = not answered, 1 = yes, 0 = no
    var imageUri: String?
    var mealType: String // "breakfast", "lunch", "dinner", "snack"
    
    var protein: Double { proteinG }
    var carbs: Double { carbsG }
    var fat: Double { fatG }
    
    init(
        date: String,
        foodName: String? = nil,
        estimatedCalories: Int = 0,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        goalCompleted: Int? = nil,
        imageUri: String? = nil,
        mealType: String = "meal"
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
        self.mealType = mealType
    }
}
