import SwiftUI

struct OnboardingView: View {
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 1
    
    // Step 1: Core Data
    @State private var gender = ""
    @State private var dob = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var workoutsPerWeek: Int? = nil
    
    // Step 2: Goals & Diet
    @State private var goal = "maintain"
    @State private var dietaryPreference = "vegetarian"
    
    // Calculations
    @State private var calculatedCalories = 0
    @State private var calculatedCarbs = 0
    @State private var calculatedProtein = 0
    @State private var calculatedFats = 0
    @State private var calculatedBurn = 500
    @State private var bmi: Double = 0
    
    var isStep1Valid: Bool {
        !gender.isEmpty && workoutsPerWeek != nil
    }
    
    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if currentStep == 1 {
                    step1View
                } else if currentStep == 2 {
                    step2View
                } else {
                    step3View
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
        }
    }
    
    // MARK: - Step 1: Basic Info
    private var step1View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Tell us about yourself")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.heavy)
                    .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gender")
                        .font(.headline)
                    HStack(spacing: 12) {
                        genderButton(title: "Male", icon: "person.fill")
                        genderButton(title: "Female", icon: "person.fill.viewfinder")
                        genderButton(title: "Other", icon: "person.text.rectangle")
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date of Birth")
                        .font(.headline)
                    DatePicker("", selection: $dob, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(colors.backgroundCard)
                        .cornerRadius(12)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Height (cm)")
                            .font(.headline)
                        Picker("Height", selection: $heightCm) {
                            ForEach(100...250, id: \.self) { cm in
                                Text("\(cm)").tag(Double(cm))
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .background(colors.backgroundCard)
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight (kg)")
                            .font(.headline)
                        Picker("Weight", selection: $weightKg) {
                            ForEach(30...200, id: \.self) { kg in
                                Text("\(kg)").tag(Double(kg))
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .background(colors.backgroundCard)
                        .cornerRadius(12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout per week")
                        .font(.headline)
                    HStack {
                        ForEach(0...7, id: \.self) { num in
                            Button {
                                workoutsPerWeek = num
                            } label: {
                                Text("\(num)")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(workoutsPerWeek == num ? colors.neonBlue : colors.backgroundCard)
                                    .foregroundColor(workoutsPerWeek == num ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                Button {
                    currentStep = 2
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isStep1Valid ? colors.neonBlue : Color.gray.opacity(0.3))
                        .cornerRadius(16)
                }
                .disabled(!isStep1Valid)
                .padding(.bottom, 20)
            }
            .padding(24)
        }
    }
    
    // MARK: - Step 2: Goals & Diet
    private var step2View: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Set your goals")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.heavy)
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("What do you want to do?")
                    .font(.headline)
                
                ForEach(["lose", "maintain", "gain"], id: \.self) { g in
                    Button {
                        goal = g
                    } label: {
                        HStack {
                            Text(g.capitalized)
                                .fontWeight(.bold)
                            Spacer()
                            if goal == g {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(colors.neonBlue)
                            }
                        }
                        .padding(16)
                        .background(colors.backgroundCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(goal == g ? colors.neonBlue : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Dietary Preference")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    dietButton(title: "Vegetarian", value: "vegetarian")
                    dietButton(title: "Non-Veg", value: "non-veg")
                }
            }
            
            Spacer()
            
            Button {
                performCalculations()
                currentStep = 3
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.neonBlue)
                    .cornerRadius(16)
            }
            .padding(.bottom, 40)
        }
        .padding(24)
    }
    
    // MARK: - Step 3: Plan Page
    private var step3View: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Daily Plan")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                    Text("Custom tailored for your goals")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    // Calories to eat
                    PlanCard(title: "Calories to Eat", value: "\(calculatedCalories)", unit: "kcal", color: colors.neonBlue)
                    
                    // Macros
                    HStack(spacing: 12) {
                        MacroCard(title: "Protein", value: "\(calculatedProtein)g", color: colors.neonGreen)
                        MacroCard(title: "Carbs", value: "\(calculatedCarbs)g", color: colors.neonOrange)
                        MacroCard(title: "Fats", value: "\(calculatedFats)g", color: colors.neonPurple)
                    }
                    
                // Calories to burn
                PlanCard(title: "Calories to Burn", value: "\(calculatedBurn)", unit: "kcal", color: colors.neonPurple)
            }
                
                Spacer(minLength: 40)
                
                Button {
                    saveProfile()
                } label: {
                    Text("Start Journey 🚀")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(colors.neonBlue)
                        .cornerRadius(16)
                }
                .padding(.bottom, 20)
            }
            .padding(24)
        }
    }
    
    // MARK: - Components
    private func genderButton(title: String, icon: String) -> some View {
        Button {
            gender = title
        } label: {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(gender == title ? colors.neonBlue : colors.backgroundCard)
            .foregroundColor(gender == title ? .white : .primary)
            .cornerRadius(12)
        }
    }
    
    private func dietButton(title: String, value: String) -> some View {
        Button {
            dietaryPreference = value
        } label: {
            Text(title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(dietaryPreference == value ? colors.neonGreen : colors.backgroundCard)
                .foregroundColor(dietaryPreference == value ? .white : .primary)
                .cornerRadius(12)
        }
    }
    
    private func performCalculations() {
        let age = HealthCalculations.age(from: dob)
        bmi = HealthCalculations.calculateBMI(heightCm: heightCm, weightKg: weightKg)
        
        let bmr = HealthCalculations.calculateBMR(gender: gender, weightKg: weightKg, heightCm: heightCm, age: age)
        let tdee = HealthCalculations.calculateTDEE(bmr: bmr, workoutsPerWeek: workoutsPerWeek ?? 0)
        calculatedCalories = HealthCalculations.adjustedCalories(tdee: tdee, goal: goal)
        
        let macros = HealthCalculations.calculateMacros(calories: calculatedCalories, goal: goal)
        calculatedCarbs = macros.carbsG
        calculatedProtein = macros.proteinG
        calculatedFats = macros.fatsG
        
        // Simple active energy goal: (TDEE - BMR) or a multiplier
        calculatedBurn = Int(max(300, tdee - bmr))
    }
    
    private func saveProfile() {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        
        let profile = UserProfile(
            gender: gender,
            dob: dob,
            heightCm: heightCm,
            weightKg: weightKg,
            workoutsPerWeek: workoutsPerWeek ?? 0,
            goal: goal,
            dietaryPreference: dietaryPreference.lowercased(),
            calculatedDailyCalories: calculatedCalories,
            calculatedDailyCarbs: calculatedCarbs,
            calculatedDailyProtein: calculatedProtein,
            calculatedDailyFats: calculatedFats,
            healthScore: 80,
            streakCount: 1,
            lastOpenedDate: String(today),
            notificationTime: "20:00",
            burnTarget: calculatedBurn
        )
        
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

struct PlanCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(24)
    }
}

struct MacroCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}
