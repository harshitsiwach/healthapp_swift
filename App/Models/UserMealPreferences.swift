import Foundation
import SwiftData

// MARK: - User Meal Preferences

@Model
final class UserMealPreferences {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // Diet Type
    var dietType: String // "vegetarian", "eggetarian", "non-vegetarian", "vegan", "jain"
    
    // Regional Preferences (JSON array)
    var preferredCuisinesJSON: String // ["north_indian", "south_indian", "gujarati", "punjabi", "bengali"]
    
    // Dietary Restrictions
    var allergiesJSON: String // from MedicalPassport or manual
    var avoidFoodsJSON: String // foods user doesn't like
    
    // Goals
    var goal: String // "lose_weight", "maintain", "gain_muscle", "eat_healthier"
    var calorieTarget: Int // 0 = auto-calculate
    var mealsPerDay: Int // 2, 3, 4, 5
    
    // Budget
    var budgetLevel: String // "budget", "moderate", "premium"
    
    // Activity Level
    var activityLevel: String // "sedentary", "light", "moderate", "active", "very_active"
    
    // Learned Preferences (auto-updated)
    var favoriteFoodsJSON: String // foods user logs frequently
    var dislikedFoodsJSON: String // foods user skips/removes
    var preferredMealTimesJSON: String // {"breakfast": "08:00", "lunch": "13:00", "dinner": "20:00"}
    var weeklyPatternsJSON: String // tracks what user eats on which days
    
    // Setup completed
    var isSetupComplete: Bool
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.dietType = "vegetarian"
        self.preferredCuisinesJSON = "[]"
        self.allergiesJSON = "[]"
        self.avoidFoodsJSON = "[]"
        self.goal = "eat_healthier"
        self.calorieTarget = 0
        self.mealsPerDay = 3
        self.budgetLevel = "moderate"
        self.activityLevel = "moderate"
        self.favoriteFoodsJSON = "[]"
        self.dislikedFoodsJSON = "[]"
        self.preferredMealTimesJSON = "{}"
        self.weeklyPatternsJSON = "{}"
        self.isSetupComplete = false
    }
    
    // MARK: - Computed
    
    var preferredCuisines: [String] {
        get { decodeJSON(preferredCuisinesJSON) }
        set { preferredCuisinesJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var allergies: [String] {
        get { decodeJSON(allergiesJSON) }
        set { allergiesJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var avoidFoods: [String] {
        get { decodeJSON(avoidFoodsJSON) }
        set { avoidFoodsJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var favoriteFoods: [String] {
        get { decodeJSON(favoriteFoodsJSON) }
        set { favoriteFoodsJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var dislikedFoods: [String] {
        get { decodeJSON(dislikedFoodsJSON) }
        set { dislikedFoodsJSON = encodeJSON(newValue); updatedAt = Date() }
    }
    
    var autoCalorieTarget: Int {
        if calorieTarget > 0 { return calorieTarget }
        // Default based on goal
        switch goal {
        case "lose_weight": return 1500
        case "gain_muscle": return 2500
        default: return 2000
        }
    }
    
    var isVeg: Bool {
        dietType == "vegetarian" || dietType == "vegan" || dietType == "jain"
    }
    
    // MARK: - Learning
    
    func recordMealLogged(_ foodName: String) {
        var favs = favoriteFoods
        if !favs.contains(foodName) {
            favs.append(foodName)
        }
        // Keep top 20
        if favs.count > 20 {
            favs = Array(favs.suffix(20))
        }
        favoriteFoods = favs
    }
    
    func recordMealSkipped(_ foodName: String) {
        var disliked = dislikedFoods
        if !disliked.contains(foodName) {
            disliked.append(foodName)
        }
        if disliked.count > 15 {
            disliked = Array(disliked.suffix(15))
        }
        dislikedFoods = disliked
    }
    
    // MARK: - Helpers
    
    private func decodeJSON<T: Decodable>(_ json: String) -> T {
        guard let data = json.data(using: .utf8),
              let result = try? JSONDecoder().decode(T.self, from: data) else {
            if T.self == [String].self { return [] as! T }
            return [:] as! T
        }
        return result
    }
    
    private func encodeJSON<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let str = String(data: data, encoding: .utf8) else { return "[]" }
        return str
    }
}

// MARK: - Meal Plan Model

struct MealPlan: Identifiable {
    let id = UUID()
    let day: String // "Monday", "Tuesday", etc.
    let meals: [PlannedMeal]
    
    var totalCalories: Int { meals.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int { meals.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Int { meals.reduce(0) { $0 + $1.carbs } }
    var totalFat: Int { meals.reduce(0) { $0 + $1.fat } }
}

struct PlannedMeal: Identifiable {
    let id = UUID()
    let type: String // "Breakfast", "Lunch", "Snack", "Dinner"
    let name: String
    let description: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let isVeg: Bool
    let cuisine: String
    let prepTime: String
    let ingredients: [String]
}
