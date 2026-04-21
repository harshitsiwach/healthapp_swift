import Foundation

// MARK: - Meal Plan Engine

class MealPlanEngine {
    
    // MARK: - Generate Weekly Plan
    
    static func generateWeeklyPlan(preferences: UserMealPreferences) -> [MealPlan] {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days.map { generateDayPlan(day: $0, preferences: preferences) }
    }
    
    static func generateDayPlan(day: String, preferences: UserMealPreferences) -> MealPlan {
        let targetCals = preferences.autoCalorieTarget
        let mealCount = preferences.mealsPerDay
        let isVeg = preferences.isVeg
        let cuisines = preferences.preferredCuisines
        let budget = preferences.budgetLevel
        
        // Distribute calories across meals
        let mealDistribution: [(type: String, pct: Double)] = mealCount == 3
            ? [("Breakfast", 0.30), ("Lunch", 0.40), ("Dinner", 0.30)]
            : mealCount == 4
            ? [("Breakfast", 0.25), ("Lunch", 0.35), ("Snack", 0.15), ("Dinner", 0.25)]
            : [("Breakfast", 0.20), ("Snack", 0.10), ("Lunch", 0.30), ("Snack", 0.10), ("Dinner", 0.30)]
        
        var meals: [PlannedMeal] = []
        
        for dist in mealDistribution {
            let mealCals = Int(Double(targetCals) * dist.pct)
            let meal = pickMeal(
                type: dist.type,
                targetCalories: mealCals,
                isVeg: isVeg,
                preferredCuisines: cuisines,
                budget: budget,
                dayOfWeek: day,
                favoriteFoods: preferences.favoriteFoods,
                dislikedFoods: preferences.dislikedFoods
            )
            meals.append(meal)
        }
        
        return MealPlan(day: day, meals: meals)
    }
    
    // MARK: - Pick Best Meal
    
    private static func pickMeal(
        type: String,
        targetCalories: Int,
        isVeg: Bool,
        preferredCuisines: [String],
        budget: String,
        dayOfWeek: String,
        favoriteFoods: [String],
        dislikedFoods: [String]
    ) -> PlannedMeal {
        
        let pool = mealDatabase.filter { meal in
            // Filter by meal type
            guard meal.type == type else { return false }
            // Filter by veg/non-veg
            if isVeg && !meal.isVeg { return false }
            // Filter out disliked foods
            if dislikedFoods.contains(where: { meal.name.lowercased().contains($0.lowercased()) }) { return false }
            // Filter by calorie range (±30%)
            let lower = Double(targetCalories) * 0.7
            let upper = Double(targetCalories) * 1.3
            return Double(meal.calories) >= lower && Double(meal.calories) <= upper
        }
        
        // Prefer favorites and matching cuisines
        let scored = pool.map { meal -> (meal: PlannedMeal, score: Double) in
            var score = 1.0
            // Favorite bonus
            if favoriteFoods.contains(where: { meal.name.contains($0) }) { score += 2.0 }
            // Cuisine match bonus
            if preferredCuisines.contains(meal.cuisine) { score += 1.5 }
            // Budget match
            if budget == "budget" && meal.calories > 400 { score += 0.5 }
            if budget == "premium" && meal.ingredients.count > 4 { score += 0.5 }
            // Variety: hash day + type for consistent but varied selection
            let hash = (dayOfWeek + type + meal.name).hashValue
            score += Double(abs(hash) % 100) / 100.0
            return (meal, score)
        }
        
        let best = scored.max(by: { $0.score < $1.score })?.meal
        return best ?? fallbackMeal(type: type, isVeg: isVeg, targetCalories: targetCalories)
    }
    
    private static func fallbackMeal(type: String, isVeg: Bool, targetCalories: Int) -> PlannedMeal {
        PlannedMeal(
            type: type,
            name: isVeg ? "Mixed Veg Curry + Roti" : "Chicken Curry + Rice",
            description: "Home-style \(type.lowercased())",
            calories: targetCalories,
            protein: isVeg ? 12 : 25,
            carbs: targetCalories / 8,
            fat: targetCalories / 40,
            isVeg: isVeg,
            cuisine: "north_indian",
            prepTime: "30 min",
            ingredients: ["Vegetables", "Spices", "Oil"]
        )
    }
    
    // MARK: - Meal Database
    
    static let mealDatabase: [PlannedMeal] = [
        // BREAKFAST - Veg
        PlannedMeal(type: "Breakfast", name: "Poha", description: "Flattened rice with peanuts, turmeric, onions", calories: 280, protein: 6, carbs: 42, fat: 10, isVeg: true, cuisine: "maharashtrian", prepTime: "15 min", ingredients: ["Poha", "Peanuts", "Onion", "Turmeric", "Green chili"]),
        PlannedMeal(type: "Breakfast", name: "Idli Sambar", description: "Steamed rice cakes with lentil stew", calories: 250, protein: 8, carbs: 45, fat: 4, isVeg: true, cuisine: "south_indian", prepTime: "20 min", ingredients: ["Rice batter", "Urad dal", "Sambar", "Coconut chutney"]),
        PlannedMeal(type: "Breakfast", name: "Upma", description: "Semolina with vegetables and mustard seeds", calories: 260, protein: 7, carbs: 38, fat: 9, isVeg: true, cuisine: "south_indian", prepTime: "15 min", ingredients: ["Rava", "Onion", "Carrot", "Peas", "Mustard seeds"]),
        PlannedMeal(type: "Breakfast", name: "Paratha + Curd", description: "Stuffed paratha with yogurt", calories: 350, protein: 10, carbs: 40, fat: 16, isVeg: true, cuisine: "punjabi", prepTime: "25 min", ingredients: ["Wheat flour", "Potato/Gobi", "Curd", "Ghee"]),
        PlannedMeal(type: "Breakfast", name: "Dosa + Chutney", description: "Crispy rice crepe with coconut chutney", calories: 270, protein: 6, carbs: 40, fat: 9, isVeg: true, cuisine: "south_indian", prepTime: "20 min", ingredients: ["Rice batter", "Coconut", "Chana dal", "Curry leaves"]),
        PlannedMeal(type: "Breakfast", name: "Besan Chilla", description: "Gram flour pancake with vegetables", calories: 240, protein: 12, carbs: 28, fat: 10, isVeg: true, cuisine: "north_indian", prepTime: "15 min", ingredients: ["Besan", "Onion", "Tomato", "Green chili", "Coriander"]),
        PlannedMeal(type: "Breakfast", name: "Aloo Puri", description: "Spiced potato curry with fried bread", calories: 420, protein: 8, carbs: 55, fat: 18, isVeg: true, cuisine: "north_indian", prepTime: "30 min", ingredients: ["Potato", "Wheat flour", "Oil", "Spices"]),
        PlannedMeal(type: "Breakfast", name: "Oats Upma", description: "Oats cooked with vegetables Indian style", calories: 230, protein: 9, carbs: 35, fat: 7, isVeg: true, cuisine: "south_indian", prepTime: "12 min", ingredients: ["Oats", "Onion", "Carrot", "Peas", "Mustard seeds"]),
        
        // BREAKFAST - Non-Veg
        PlannedMeal(type: "Breakfast", name: "Egg Bhurji + Toast", description: "Indian scrambled eggs with bread", calories: 320, protein: 18, carbs: 28, fat: 16, isVeg: false, cuisine: "north_indian", prepTime: "12 min", ingredients: ["Eggs", "Onion", "Tomato", "Green chili", "Bread"]),
        PlannedMeal(type: "Breakfast", name: "Masala Omelette", description: "Spiced omelette with onions and tomatoes", calories: 280, protein: 16, carbs: 8, fat: 20, isVeg: false, cuisine: "north_indian", prepTime: "10 min", ingredients: ["Eggs", "Onion", "Tomato", "Green chili", "Coriander"]),
        PlannedMeal(type: "Breakfast", name: "Chicken Keema Paratha", description: "Minced chicken stuffed paratha", calories: 450, protein: 28, carbs: 38, fat: 20, isVeg: false, cuisine: "punjabi", prepTime: "30 min", ingredients: ["Chicken mince", "Wheat flour", "Onion", "Spices"]),
        
        // LUNCH - Veg
        PlannedMeal(type: "Lunch", name: "Rajma Chawal", description: "Kidney bean curry with steamed rice", calories: 420, protein: 15, carbs: 65, fat: 10, isVeg: true, cuisine: "punjabi", prepTime: "45 min", ingredients: ["Rajma", "Rice", "Onion", "Tomato", "Garam masala"]),
        PlannedMeal(type: "Lunch", name: "Dal Tadka + Roti", description: "Yellow lentils with tempered spices and bread", calories: 380, protein: 14, carbs: 55, fat: 10, isVeg: true, cuisine: "north_indian", prepTime: "30 min", ingredients: ["Toor dal", "Ghee", "Cumin", "Garlic", "Wheat flour"]),
        PlannedMeal(type: "Lunch", name: "Paneer Butter Masala + Naan", description: "Creamy tomato paneer curry", calories: 520, protein: 20, carbs: 45, fat: 28, isVeg: true, cuisine: "punjabi", prepTime: "35 min", ingredients: ["Paneer", "Tomato", "Cream", "Butter", "Maida"]),
        PlannedMeal(type: "Lunch", name: "Curd Rice", description: "Yogurt rice with tempering", calories: 320, protein: 8, carbs: 52, fat: 8, isVeg: true, cuisine: "south_indian", prepTime: "15 min", ingredients: ["Rice", "Curd", "Mustard seeds", "Curry leaves", "Ginger"]),
        PlannedMeal(type: "Lunch", name: "Vegetable Biryani", description: "Fragrant rice with mixed vegetables", calories: 400, protein: 10, carbs: 60, fat: 14, isVeg: true, cuisine: "hyderabadi", prepTime: "45 min", ingredients: ["Basmati rice", "Mixed veg", "Saffron", "Fried onions", "Yogurt"]),
        PlannedMeal(type: "Lunch", name: "Palak Paneer + Roti", description: "Spinach cottage cheese curry", calories: 420, protein: 18, carbs: 40, fat: 22, isVeg: true, cuisine: "punjabi", prepTime: "30 min", ingredients: ["Spinach", "Paneer", "Onion", "Garlic", "Wheat flour"]),
        PlannedMeal(type: "Lunch", name: "Chole Bhature", description: "Chickpea curry with fried bread", calories: 550, protein: 14, carbs: 60, fat: 28, isVeg: true, cuisine: "punjabi", prepTime: "40 min", ingredients: ["Chickpeas", "Maida", "Onion", "Tea (for color)", "Spices"]),
        PlannedMeal(type: "Lunch", name: "Khichdi", description: "Comforting rice and lentil porridge", calories: 300, protein: 12, carbs: 48, fat: 6, isVeg: true, cuisine: "gujarati", prepTime: "25 min", ingredients: ["Rice", "Moong dal", "Ghee", "Cumin", "Turmeric"]),
        PlannedMeal(type: "Lunch", name: "Sambar Rice", description: "Lentil stew mixed with rice", calories: 360, protein: 12, carbs: 55, fat: 10, isVeg: true, cuisine: "south_indian", prepTime: "30 min", ingredients: ["Rice", "Toor dal", "Tamarind", "Drumstick", "Sambar powder"]),
        
        // LUNCH - Non-Veg
        PlannedMeal(type: "Lunch", name: "Butter Chicken + Naan", description: "Creamy tomato chicken curry", calories: 580, protein: 32, carbs: 42, fat: 30, isVeg: false, cuisine: "punjabi", prepTime: "40 min", ingredients: ["Chicken", "Tomato", "Cream", "Butter", "Maida"]),
        PlannedMeal(type: "Lunch", name: "Chicken Biryani", description: "Fragrant rice with spiced chicken", calories: 520, protein: 28, carbs: 55, fat: 20, isVeg: false, cuisine: "hyderabadi", prepTime: "60 min", ingredients: ["Basmati rice", "Chicken", "Saffron", "Fried onions", "Yogurt"]),
        PlannedMeal(type: "Lunch", name: "Fish Curry + Rice", description: "Coconut fish curry with steamed rice", calories: 450, protein: 28, carbs: 48, fat: 16, isVeg: false, cuisine: "kerala", prepTime: "30 min", ingredients: ["Fish", "Coconut", "Tamarind", "Curry leaves", "Rice"]),
        PlannedMeal(type: "Lunch", name: "Egg Curry + Roti", description: "Boiled eggs in spiced gravy", calories: 380, protein: 18, carbs: 35, fat: 18, isVeg: false, cuisine: "north_indian", prepTime: "25 min", ingredients: ["Eggs", "Onion", "Tomato", "Spices", "Wheat flour"]),
        PlannedMeal(type: "Lunch", name: "Mutton Rogan Josh + Rice", description: "Kashmiri lamb curry", calories: 550, protein: 30, carbs: 45, fat: 28, isVeg: false, cuisine: "kashmiri", prepTime: "90 min", ingredients: ["Mutton", "Yogurt", "Kashmiri chili", "Fennel", "Rice"]),
        
        // DINNER - Veg
        PlannedMeal(type: "Dinner", name: "Mixed Veg Curry + Roti", description: "Seasonal vegetables in light gravy", calories: 350, protein: 12, carbs: 45, fat: 14, isVeg: true, cuisine: "north_indian", prepTime: "30 min", ingredients: ["Mixed vegetables", "Onion", "Tomato", "Spices", "Wheat flour"]),
        PlannedMeal(type: "Dinner", name: "Dal Fry + Rice", description: "Tempered lentils with steamed rice", calories: 360, protein: 14, carbs: 55, fat: 8, isVeg: true, cuisine: "north_indian", prepTime: "25 min", ingredients: ["Masoor dal", "Onion", "Garlic", "Ghee", "Rice"]),
        PlannedMeal(type: "Dinner", name: "Bhindi Masala + Roti", description: "Spiced okra with bread", calories: 320, protein: 8, carbs: 42, fat: 14, isVeg: true, cuisine: "north_indian", prepTime: "25 min", ingredients: ["Okra", "Onion", "Tomato", "Amchur", "Wheat flour"]),
        PlannedMeal(type: "Dinner", name: "Vegetable Pulao", description: "One-pot spiced rice with vegetables", calories: 340, protein: 8, carbs: 52, fat: 12, isVeg: true, cuisine: "north_indian", prepTime: "30 min", ingredients: ["Basmati rice", "Mixed veg", "Ghee", "Whole spices", "Saffron"]),
        PlannedMeal(type: "Dinner", name: "Aloo Gobi + Roti", description: "Potato cauliflower dry curry", calories: 330, protein: 8, carbs: 48, fat: 12, isVeg: true, cuisine: "punjabi", prepTime: "25 min", ingredients: ["Potato", "Cauliflower", "Onion", "Turmeric", "Wheat flour"]),
        
        // DINNER - Non-Veg
        PlannedMeal(type: "Dinner", name: "Chicken Tikka Masala + Naan", description: "Grilled chicken in creamy sauce", calories: 520, protein: 30, carbs: 40, fat: 26, isVeg: false, cuisine: "punjabi", prepTime: "40 min", ingredients: ["Chicken", "Yogurt", "Cream", "Spices", "Maida"]),
        PlannedMeal(type: "Dinner", name: "Tandoori Chicken + Salad", description: "Oven-roasted spiced chicken", calories: 380, protein: 35, carbs: 8, fat: 22, isVeg: false, cuisine: "punjabi", prepTime: "45 min", ingredients: ["Chicken", "Yogurt", "Tandoori masala", "Lemon", "Onion"]),
        PlannedMeal(type: "Dinner", name: "Prawn Masala + Rice", description: "Spiced prawn curry", calories: 420, protein: 28, carbs: 42, fat: 16, isVeg: false, cuisine: "south_indian", prepTime: "25 min", ingredients: ["Prawns", "Coconut", "Onion", "Tomato", "Rice"]),
        
        // SNACKS
        PlannedMeal(type: "Snack", name: "Fruit Chaat", description: "Mixed fruits with chaat masala", calories: 120, protein: 2, carbs: 28, fat: 1, isVeg: true, cuisine: "north_indian", prepTime: "5 min", ingredients: ["Apple", "Banana", "Pomegranate", "Chaat masala", "Lemon"]),
        PlannedMeal(type: "Snack", name: "Roasted Chana", description: "Spiced roasted chickpeas", calories: 150, protein: 8, carbs: 22, fat: 3, isVeg: true, cuisine: "north_indian", prepTime: "5 min", ingredients: ["Chickpeas", "Salt", "Chaat masala", "Lemon"]),
        PlannedMeal(type: "Snack", name: "Sprouts Chaat", description: "Mixed sprouts with onion and tomato", calories: 140, protein: 10, carbs: 20, fat: 2, isVeg: true, cuisine: "north_indian", prepTime: "10 min", ingredients: ["Moong sprouts", "Onion", "Tomato", "Lemon", "Coriander"]),
        PlannedMeal(type: "Snack", name: "Makhana", description: "Roasted fox nuts with light spices", calories: 100, protein: 4, carbs: 15, fat: 2, isVeg: true, cuisine: "north_indian", prepTime: "8 min", ingredients: ["Makhana", "Ghee", "Salt", "Black pepper"]),
        PlannedMeal(type: "Snack", name: "Boiled Egg", description: "Simple boiled egg with salt and pepper", calories: 80, protein: 6, carbs: 1, fat: 5, isVeg: false, cuisine: "north_indian", prepTime: "10 min", ingredients: ["Egg", "Salt", "Pepper"]),
        PlannedMeal(type: "Snack", name: "Peanut Chikki", description: "Jaggery peanut brittle", calories: 180, protein: 5, carbs: 22, fat: 9, isVeg: true, cuisine: "maharashtrian", prepTime: "2 min", ingredients: ["Peanuts", "Jaggery"]),
    ]
    
    // MARK: - Adapt Preferences from Logs
    
    static func adaptPreferences(preferences: UserMealPreferences, recentLogs: [DailyLog]) {
        // Count food frequency
        var frequency: [String: Int] = [:]
        for log in recentLogs {
            if let name = log.foodName {
                frequency[name, default: 0] += 1
            }
        }
        
        // Update favorites (logged 3+ times recently)
        let newFavorites = frequency.filter { $0.value >= 3 }.map { $0.key }
        if !newFavorites.isEmpty {
            var favs = preferences.favoriteFoods
            for fav in newFavorites where !favs.contains(fav) {
                favs.append(fav)
            }
            preferences.favoriteFoods = Array(favs.suffix(20))
        }
        
        // Adjust calorie target based on weight trend (if available)
        // This would integrate with HealthKit weight data
    }
}
