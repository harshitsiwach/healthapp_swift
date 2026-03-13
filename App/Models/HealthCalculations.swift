import Foundation

struct HealthCalculations {
    
    // MARK: - BMI
    
    static func calculateBMI(heightCm: Double, weightKg: Double) -> Double {
        let heightM = heightCm / 100.0
        guard heightM > 0 else { return 0 }
        return weightKg / (heightM * heightM)
    }
    
    static func bmiClassification(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Healthy"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    
    static func bmiDescription(_ bmi: Double, goal: String) -> String {
        let classification = bmiClassification(bmi)
        switch classification {
        case "Underweight":
            return "Your BMI indicates you're underweight. Focus on nutrient-dense meals to build healthy mass."
        case "Healthy":
            return "Great news! Your BMI is in the healthy range. Let's keep it that way with balanced nutrition."
        case "Overweight":
            return "Your BMI is slightly above the healthy range. Small dietary changes can make a big difference."
        case "Obese":
            return "Your BMI suggests some health risks. We'll create a sustainable plan to help you get healthier."
        default:
            return ""
        }
    }
    
    // MARK: - Recommended Goal Badge
    
    static func recommendedGoal(bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "gain"
        case 18.5..<25: return "maintain"
        default: return "lose"
        }
    }
    
    // MARK: - BMR (Mifflin-St Jeor)
    
    static func calculateBMR(gender: String, weightKg: Double, heightCm: Double, age: Int) -> Double {
        if gender.lowercased() == "male" {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }
    
    // MARK: - TDEE
    
    static func activityMultiplier(workoutsPerWeek: Int) -> Double {
        switch workoutsPerWeek {
        case 0: return 1.2
        case 1...2: return 1.375
        case 3...4: return 1.55
        case 5...6: return 1.725
        default: return 1.9
        }
    }
    
    static func calculateTDEE(bmr: Double, workoutsPerWeek: Int) -> Double {
        return bmr * activityMultiplier(workoutsPerWeek: workoutsPerWeek)
    }
    
    // MARK: - Goal Adjusted Calories
    
    static func adjustedCalories(tdee: Double, goal: String) -> Int {
        switch goal.lowercased() {
        case "lose": return Int(tdee - 500)
        case "gain": return Int(tdee + 500)
        default: return Int(tdee)
        }
    }
    
    // MARK: - Macros (Indian Diet Adjusted)
    
    struct MacroBreakdown {
        let carbsG: Int
        let proteinG: Int
        let fatsG: Int
    }
    
    static func calculateMacros(calories: Int, goal: String) -> MacroBreakdown {
        let carbPercent: Double
        let proteinPercent: Double
        let fatPercent: Double
        
        if goal.lowercased() == "lose" {
            carbPercent = 0.40
            proteinPercent = 0.35
            fatPercent = 0.25
        } else {
            // maintain or gain
            carbPercent = 0.50
            proteinPercent = 0.25
            fatPercent = 0.25
        }
        
        let carbsG = Int((Double(calories) * carbPercent) / 4.0)
        let proteinG = Int((Double(calories) * proteinPercent) / 4.0)
        let fatsG = Int((Double(calories) * fatPercent) / 9.0)
        
        return MacroBreakdown(carbsG: carbsG, proteinG: proteinG, fatsG: fatsG)
    }
    
    // MARK: - Age from DOB
    
    static func age(from dob: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 25
    }
    
    // MARK: - Health Score
    
    static func calculateInitialHealthScore(bmi: Double, workoutsPerWeek: Int) -> Int {
        var score = 100
        
        // BMI deductions
        let classification = bmiClassification(bmi)
        switch classification {
        case "Underweight": score -= 15
        case "Overweight": score -= 15
        case "Obese": score -= 30
        default: break
        }
        
        // Workout deductions
        if workoutsPerWeek == 0 {
            score -= 20
        } else if workoutsPerWeek <= 1 {
            score -= 10
        }
        
        return max(0, min(100, score))
    }
}
