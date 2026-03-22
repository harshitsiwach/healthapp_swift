import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentStep = 1
    
    // Step 1
    @State private var gender = "Male"
    @State private var workoutsPerWeek = 3
    
    // Step 2
    @State private var dob = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    
    // Step 3
    @State private var goal = "maintain"
    @State private var dietaryPreference = "vegetarian"
    
    // Step 4
    @State private var isCalculating = true
    @State private var calculatedCalories = 0
    @State private var calculatedCarbs = 0
    @State private var calculatedProtein = 0
    @State private var calculatedFats = 0
    @State private var bmi: Double = 0
    @State private var healthScore = 80
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 0) {
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(Color.gray.opacity(0.2)))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Content
                TabView(selection: $currentStep) {
                    step1View.tag(1)
                    step2View.tag(2)
                    step3View.tag(3)
                    step4View.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
    }
    
    // MARK: - Step 1: Gender & Workouts
    
    private var step1View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                AppLogo(size: .large, showText: true)
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Let's get started")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                    Text("Tell us about yourself")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Gender")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    ChipGroup(options: ["Male", "Female", "Other"], selected: $gender)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Workouts per week")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    NumberChipGroup(range: 0...7, selected: $workoutsPerWeek)
                }
                
                Spacer(minLength: 40)
                
                nextButton { currentStep = 2 }
            }
            .padding(24)
        }
    }
    
    // MARK: - Step 2: Physical Data
    
    private var step2View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Body")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                    Text("We need this to calculate your needs")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Date of Birth")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    
                    GlassCard {
                        DatePicker("", selection: $dob, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height (cm)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        
                        GlassCard(padding: 12) {
                            Picker("Height", selection: Binding(
                                get: { Int(heightCm) },
                                set: { heightCm = Double($0) }
                            )) {
                                ForEach(100...250, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        
                        GlassCard(padding: 12) {
                            Picker("Weight", selection: Binding(
                                get: { Int(weightKg) },
                                set: { weightKg = Double($0) }
                            )) {
                                ForEach(30...200, id: \.self) { kg in
                                    Text("\(kg) kg").tag(kg)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                HStack {
                    backButton { currentStep = 1 }
                    nextButton { currentStep = 3 }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Step 3: Goals & Preferences
    
    private var step3View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Goals")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                    Text("We'll tailor everything for you")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                let currentBMI = HealthCalculations.calculateBMI(heightCm: heightCm, weightKg: weightKg)
                let recommended = HealthCalculations.recommendedGoal(bmi: currentBMI)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Goal")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        goalCard(title: "Lose Weight", value: "lose", icon: "flame.fill", recommended: recommended)
                        goalCard(title: "Maintain", value: "maintain", icon: "equal.circle.fill", recommended: recommended)
                        goalCard(title: "Gain Muscle", value: "gain", icon: "dumbbell.fill", recommended: recommended)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dietary Preference")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    ChipGroup(
                        options: ["Vegetarian", "Vegan", "Eggetarian", "Non-Veg"],
                        selected: $dietaryPreference,
                        accentColor: .green
                    )
                }
                
                Spacer(minLength: 40)
                
                HStack {
                    backButton { currentStep = 2 }
                    nextButton {
                        currentStep = 4
                        performCalculations()
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Step 4: Results
    
    private var step4View: some View {
        ScrollView {
            VStack(spacing: 32) {
                if isCalculating {
                    VStack(spacing: 20) {
                        Spacer(minLength: 100)
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating Your Plan...")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Plan")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.heavy)
                        
                        let classification = HealthCalculations.bmiClassification(bmi)
                        Text("BMI: \(String(format: "%.1f", bmi)) — \(classification)")
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Text(HealthCalculations.bmiDescription(bmi, goal: goal))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Calorie Card
                    GlassCard(material: .regularMaterial, cornerRadius: 24) {
                        VStack(spacing: 12) {
                            Text("Daily Calories")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text("\(calculatedCalories)")
                                .font(.system(size: 56, weight: .heavy, design: .rounded))
                                .foregroundStyle(.blue)
                            Text("kcal/day")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Macros
                    HStack(spacing: 12) {
                        macroResultCard(label: "Carbs", value: "\(calculatedCarbs)g", color: .orange)
                        macroResultCard(label: "Protein", value: "\(calculatedProtein)g", color: .green)
                        macroResultCard(label: "Fats", value: "\(calculatedFats)g", color: .purple)
                    }
                    
                    // Health Score
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Health Score")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                Text("Based on your BMI & activity")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(healthScore)")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundStyle(healthScore >= 70 ? .green : healthScore >= 50 ? .orange : .red)
                            Text("/100")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    Button {
                        saveProfile()
                    } label: {
                        Text("Start Your Journey 🚀")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Helpers
    
    private func goalCard(title: String, value: String, icon: String, recommended: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { goal = value }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(goal == value ? .white : .blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(goal == value ? Color.blue : Color.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    if recommended == value {
                        Text("💡 Recommended")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                if goal == value {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(goal == value ? Color.blue.opacity(0.08) : .clear)
            )
            .background(
                Group {
                    if #available(iOS 26, *) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.clear)
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(goal == value ? Color.blue.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func macroResultCard(label: String, value: String, color: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(spacing: 8) {
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func nextButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Continue")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
                .background(
                    Group {
                        if #available(iOS 26, *) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.clear)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Calculations
    
    private func performCalculations() {
        isCalculating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let age = HealthCalculations.age(from: dob)
            bmi = HealthCalculations.calculateBMI(heightCm: heightCm, weightKg: weightKg)
            
            let bmr = HealthCalculations.calculateBMR(gender: gender, weightKg: weightKg, heightCm: heightCm, age: age)
            let tdee = HealthCalculations.calculateTDEE(bmr: bmr, workoutsPerWeek: workoutsPerWeek)
            calculatedCalories = HealthCalculations.adjustedCalories(tdee: tdee, goal: goal)
            
            let macros = HealthCalculations.calculateMacros(calories: calculatedCalories, goal: goal)
            calculatedCarbs = macros.carbsG
            calculatedProtein = macros.proteinG
            calculatedFats = macros.fatsG
            
            healthScore = HealthCalculations.calculateInitialHealthScore(bmi: bmi, workoutsPerWeek: workoutsPerWeek)
            
            withAnimation(.spring(response: 0.6)) {
                isCalculating = false
            }
        }
    }
    
    private func saveProfile() {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        
        let profile = UserProfile(
            gender: gender,
            dob: dob,
            heightCm: heightCm,
            weightKg: weightKg,
            workoutsPerWeek: workoutsPerWeek,
            goal: goal,
            dietaryPreference: dietaryPreference.lowercased(),
            calculatedDailyCalories: calculatedCalories,
            calculatedDailyCarbs: calculatedCarbs,
            calculatedDailyProtein: calculatedProtein,
            calculatedDailyFats: calculatedFats,
            healthScore: healthScore,
            streakCount: 1,
            lastOpenedDate: String(today),
            notificationTime: "20:00"
        )
        
        modelContext.insert(profile)
        try? modelContext.save()
        
        // Trigger the transition to the main app
        hasCompletedOnboarding = true
    }
}
