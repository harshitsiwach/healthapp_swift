import Foundation

// MARK: - Food Understanding Pipeline

// MARK: Meal Input Parser

struct MealInputParser {
    
    struct ParsedMeal {
        let rawInput: String
        let dishCandidates: [String]
        let estimatedPortionDescription: String?
        let needsClarification: Bool
    }
    
    func parse(_ input: String) -> ParsedMeal {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by "and", ",", "with", "+"
        let separators = [" and ", ", ", " with ", " + "]
        var items = [cleaned]
        
        for separator in separators {
            items = items.flatMap { $0.components(separatedBy: separator) }
        }
        
        let candidates = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        return ParsedMeal(
            rawInput: cleaned,
            dishCandidates: candidates,
            estimatedPortionDescription: nil,
            needsClarification: candidates.isEmpty
        )
    }
}

// MARK: Food Normalizer

struct FoodNormalizer {
    
    // Common Indian food aliases
    private let aliases: [String: String] = [
        "chapati": "roti",
        "chapatti": "roti",
        "phulka": "roti",
        "naan": "naan bread",
        "daal": "dal",
        "dhal": "dal",
        "chawal": "rice",
        "bhaat": "rice",
        "sabzi": "mixed vegetable curry",
        "subzi": "mixed vegetable curry",
        "chai": "masala chai",
        "curd": "yogurt",
        "dahi": "yogurt",
        "paneer": "paneer (cottage cheese)",
        "aloo": "potato",
        "gobhi": "cauliflower",
        "rajma": "kidney beans curry",
        "chole": "chickpea curry",
        "chana": "chickpea",
        "poha": "flattened rice",
        "upma": "semolina porridge",
        "idli": "steamed rice cake",
        "dosa": "rice and lentil crepe",
        "vada": "deep fried lentil fritter",
        "samosa": "fried pastry with filling",
        "paratha": "layered flatbread",
    ]
    
    func normalize(_ name: String) -> String {
        let lowered = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return aliases[lowered] ?? lowered
    }
}

// MARK: Portion Estimator

struct PortionEstimator {
    
    struct PortionEstimate {
        let servings: Double
        let description: String
    }
    
    // Extract portion numbers from text like "2 roti" or "1 bowl rice"
    func estimate(from text: String) -> PortionEstimate {
        let pattern = #"(\d+(?:\.\d+)?)\s*"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            let numberStr = String(text[match]).trimmingCharacters(in: .whitespaces)
            let servings = Double(numberStr) ?? 1.0
            return PortionEstimate(servings: servings, description: "\(Int(servings)) serving(s)")
        }
        return PortionEstimate(servings: 1.0, description: "1 standard serving")
    }
}

// MARK: Nutrition Lookup Service

struct NutritionLookupService {
    
    struct NutritionInfo {
        let name: String
        let caloriesPer100g: Int
        let proteinPer100g: Double
        let carbsPer100g: Double
        let fatPer100g: Double
        let standardServingG: Double
    }
    
    // Local nutrition database for common Indian foods
    private let database: [String: NutritionInfo] = [
        "roti": NutritionInfo(name: "Roti (Wheat)", caloriesPer100g: 297, proteinPer100g: 9.8, carbsPer100g: 50.0, fatPer100g: 6.5, standardServingG: 30),
        "rice": NutritionInfo(name: "Steamed Rice", caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28.2, fatPer100g: 0.3, standardServingG: 150),
        "dal": NutritionInfo(name: "Dal (Lentils)", caloriesPer100g: 116, proteinPer100g: 9.0, carbsPer100g: 20.0, fatPer100g: 0.4, standardServingG: 150),
        "paneer (cottage cheese)": NutritionInfo(name: "Paneer", caloriesPer100g: 265, proteinPer100g: 18.3, carbsPer100g: 1.2, fatPer100g: 20.8, standardServingG: 100),
        "chicken curry": NutritionInfo(name: "Chicken Curry", caloriesPer100g: 160, proteinPer100g: 15.0, carbsPer100g: 6.0, fatPer100g: 9.0, standardServingG: 200),
        "yogurt": NutritionInfo(name: "Plain Yogurt", caloriesPer100g: 61, proteinPer100g: 3.5, carbsPer100g: 4.7, fatPer100g: 3.3, standardServingG: 100),
        "masala chai": NutritionInfo(name: "Masala Chai", caloriesPer100g: 37, proteinPer100g: 1.4, carbsPer100g: 4.5, fatPer100g: 1.5, standardServingG: 150),
        "steamed rice cake": NutritionInfo(name: "Idli", caloriesPer100g: 130, proteinPer100g: 4.0, carbsPer100g: 24.0, fatPer100g: 1.0, standardServingG: 40),
        "rice and lentil crepe": NutritionInfo(name: "Dosa", caloriesPer100g: 168, proteinPer100g: 4.5, carbsPer100g: 28.0, fatPer100g: 4.0, standardServingG: 80),
        "paratha": NutritionInfo(name: "Aloo Paratha", caloriesPer100g: 260, proteinPer100g: 5.5, carbsPer100g: 30.0, fatPer100g: 13.0, standardServingG: 80),
        "samosa": NutritionInfo(name: "Samosa", caloriesPer100g: 262, proteinPer100g: 4.4, carbsPer100g: 32.0, fatPer100g: 13.0, standardServingG: 60),
    ]
    
    func lookup(_ normalizedName: String) -> NutritionInfo? {
        return database[normalizedName]
    }
    
    func lookupAll() -> [NutritionInfo] {
        Array(database.values)
    }
}

// MARK: Food Explanation Service

struct FoodExplanationService {
    
    struct FoodExplanation {
        let dishName: String
        let confidenceBand: String // "high", "medium", "low"
        let estimatedPortion: String
        let calories: Int
        let macroSummary: String
        let goodPoints: [String]
        let cautions: [String]
        let healthierAlternative: String?
    }
    
    func explain(
        foodName: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        userGoal: String
    ) -> FoodExplanation {
        var goodPoints: [String] = []
        var cautions: [String] = []
        var alternative: String? = nil
        
        // Analyze macros
        if protein > 15 {
            goodPoints.append("Good source of protein (%.1fg)".replacingOccurrences(of: "%.1f", with: String(format: "%.1f", protein)))
        }
        if fat < 10 {
            goodPoints.append("Low in fat")
        }
        if calories < 300 {
            goodPoints.append("Light meal, calorie-friendly")
        }
        
        if fat > 20 {
            cautions.append("High in fat — consider smaller portions")
        }
        if carbs > 60 {
            cautions.append("High in carbs — might spike blood sugar")
        }
        if calories > 600 {
            cautions.append("Calorie-dense meal — balance with lighter meals later")
        }
        
        // Goal-based suggestions
        if userGoal == "lose" && calories > 400 {
            alternative = "Consider a grilled version or reduce oil for fewer calories"
        }
        
        return FoodExplanation(
            dishName: foodName,
            confidenceBand: "high",
            estimatedPortion: "1 standard serving",
            calories: calories,
            macroSummary: "P: \(String(format: "%.0f", protein))g | C: \(String(format: "%.0f", carbs))g | F: \(String(format: "%.0f", fat))g",
            goodPoints: goodPoints.isEmpty ? ["Balanced meal"] : goodPoints,
            cautions: cautions,
            healthierAlternative: alternative
        )
    }
}
