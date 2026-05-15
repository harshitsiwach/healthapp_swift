import SwiftUI
import SwiftData

// MARK: - Meal Plan Setup Wizard

struct MealPlanSetupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    @Query private var allPreferences: [UserMealPreferences]
    
    @State private var step = 0
    @State private var dietType = "vegetarian"
    @State private var selectedCuisines: Set<String> = []
    @State private var goal = "eat_healthier"
    @State private var mealsPerDay = 3
    @State private var budgetLevel = "moderate"
    @State private var activityLevel = "moderate"
    @State private var avoidFoods: [String] = []
    @State private var newAvoidFood = ""
    
    let onComplete: () -> Void
    
    private var preferences: UserMealPreferences {
        if let existing = allPreferences.first { return existing }
        let new = UserMealPreferences()
        modelContext.insert(new)
        return new
    }
    
    let totalSteps = 5
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                ProgressView(value: Double(step + 1), total: Double(totalSteps))
                    .tint(colors.neonGreen)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Text("Step \(step + 1) of \(totalSteps)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textTertiary)
                    .padding(.top, 4)
                
                TabView(selection: $step) {
                    dietTypeStep.tag(0)
                    cuisineStep.tag(1)
                    goalStep.tag(2)
                    budgetStep.tag(3)
                    avoidFoodsStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.smooth, value: step)
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Meal Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step > 0 {
                        Button("Back") { withAnimation { step -= 1 } }
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(step == totalSteps - 1 ? "Done" : "Next") {
                        if step < totalSteps - 1 {
                            withAnimation { step += 1 }
                        } else {
                            saveAndComplete()
                        }
                    }
                    .foregroundStyle(colors.neonGreen)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    // MARK: - Step 1: Diet Type
    
    private var dietTypeStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                stepHeader(icon: "leaf.fill", title: "What do you eat?", subtitle: "This helps us suggest the right meals for you")
                
                ForEach([
                    ("vegetarian", "Vegetarian", "Veggies, dairy, no meat or eggs", "leaf.fill"),
                    ("eggetarian", "Eggetarian", "Vegetarian + eggs", "egg.fill"),
                    ("non-vegetarian", "Non-Vegetarian", "Everything including meat", "fork.knife"),
                    ("vegan", "Vegan", "No animal products", "leaf.circle.fill"),
                    ("jain", "Jain", "No onion, garlic, root vegetables", "heart.fill"),
                ], id: \.0) { type, title, desc, icon in
                    dietOption(type: type, title: title, desc: desc, icon: icon)
                }
                
                Spacer().frame(height: 100)
            }
            .padding()
        }
    }
    
    private func dietOption(type: String, title: String, desc: String, icon: String) -> some View {
        let isSelected = dietType == type
        return Button {
            Haptic.selection()
            withAnimation(.spring(response: 0.3)) { dietType = type }
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? colors.neonGreen : colors.textTertiary)
                    .frame(width: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.textPrimary)
                    Text(desc)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? colors.neonGreen : colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? colors.neonGreen.opacity(0.08) : colors.backgroundElevated)
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(isSelected ? colors.neonGreen.opacity(0.4) : colors.cardBorder))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 2: Cuisine Preferences
    
    private var cuisineStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                stepHeader(icon: "globe.asia.australia", title: "Favorite cuisines?", subtitle: "Select all that you enjoy")
                
                let cuisines = [
                    ("north_indian", "North Indian", "Roti, dal, sabzi"),
                    ("south_indian", "South Indian", "Dosa, idli, sambar"),
                    ("punjabi", "Punjabi", "Butter chicken, naan, lassi"),
                    ("gujarati", "Gujarati", "Dhokla, thepla, undhiyu"),
                    ("bengali", "Bengali", "Fish curry, rosogolla"),
                    ("maharashtrian", "Maharashtrian", "Puran poli, vada pav"),
                    ("kerala", "Kerala", "Appam, fish moilee"),
                    ("hyderabadi", "Hyderabadi", "Biryani, haleem"),
                    ("rajasthani", "Rajasthani", "Dal baati, gatte"),
                    ("tamil", "Tamil", "Chettinad, filter coffee"),
                ]
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(cuisines, id: \.0) { id, name, desc in
                        cuisineChip(id: id, name: name, desc: desc)
                    }
                }
                
                Spacer().frame(height: 100)
            }
            .padding()
        }
    }
    
    private func cuisineChip(id: String, name: String, desc: String) -> some View {
        let isSelected = selectedCuisines.contains(id)
        return Button {
            Haptic.selection()
            if isSelected { selectedCuisines.remove(id) } else { selectedCuisines.insert(id) }
        } label: {
            VStack(spacing: 4) {
                Text(name)
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(isSelected ? .white : colors.textPrimary)
                Text(desc)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? colors.neonGreen : colors.backgroundElevated)
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(isSelected ? colors.neonGreen : colors.cardBorder))
            )
        }
        .buttonStyle(.scaleButton)
    }
    
    // MARK: - Step 3: Goals
    
    private var goalStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                stepHeader(icon: "target", title: "What's your goal?", subtitle: "We'll customize your meal plans accordingly")
                
                ForEach([
                    ("lose_weight", "Lose Weight", "Calorie deficit, lighter meals", "arrow.down.heart.fill"),
                    ("maintain", "Maintain Weight", "Balanced nutrition", "scalemass.fill"),
                    ("gain_muscle", "Gain Muscle", "High protein, calorie surplus", "figure.strengthtraining.traditional"),
                    ("eat_healthier", "Eat Healthier", "More whole foods, less processed", "heart.fill"),
                ], id: \.0) { id, title, desc, icon in
                    Button {
                        Haptic.selection()
                        withAnimation(.spring(response: 0.3)) { goal = id }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .foregroundStyle(goal == id ? colors.neonGreen : colors.textTertiary)
                                .frame(width: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(DesignSystem.Typography.bodyBold).foregroundStyle(colors.textPrimary)
                                Text(desc).font(DesignSystem.Typography.caption).foregroundStyle(colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: goal == id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(goal == id ? colors.neonGreen : colors.textTertiary)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(goal == id ? colors.neonGreen.opacity(0.08) : colors.backgroundElevated)
                                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .strokeBorder(goal == id ? colors.neonGreen.opacity(0.4) : colors.cardBorder))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Meals per day
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Meals per day")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.textPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach([2, 3, 4, 5], id: \.self) { count in
                            Button {
                                Haptic.selection()
                                mealsPerDay = count
                            } label: {
                                Text("\(count)")
                                    .font(DesignSystem.Typography.bodyBold)
                                    .foregroundStyle(mealsPerDay == count ? .white : colors.textPrimary)
                                    .frame(width: 50, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                            .fill(mealsPerDay == count ? colors.neonGreen : colors.backgroundElevated)
                                    )
                            }
                            .buttonStyle(.scaleButton)
                        }
                    }
                }
                .padding(.top)
                
                Spacer().frame(height: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Step 4: Budget & Activity
    
    private var budgetStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                stepHeader(icon: "indianrupeesign", title: "Budget & Lifestyle", subtitle: "This helps us suggest practical meals")
                
                Text("Budget")
                    .font(DesignSystem.Typography.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    ForEach([("budget", "Budget"), ("moderate", "Moderate"), ("premium", "Premium")], id: \.0) { id, label in
                        Button {
                            Haptic.selection()
                            budgetLevel = id
                        } label: {
                            Text(label)
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundStyle(budgetLevel == id ? .white : colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(budgetLevel == id ? colors.neonBlue : colors.backgroundElevated)
                                )
                        }
                        .buttonStyle(.scaleButton)
                    }
                }
                
                Text("Activity Level")
                    .font(DesignSystem.Typography.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                
                ForEach([
                    ("sedentary", "Sedentary", "Desk job, little exercise"),
                    ("light", "Lightly Active", "Light exercise 1-3 days/week"),
                    ("moderate", "Moderate", "Exercise 3-5 days/week"),
                    ("active", "Active", "Hard exercise 6-7 days/week"),
                ], id: \.0) { id, title, desc in
                    Button {
                        Haptic.selection()
                        activityLevel = id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(DesignSystem.Typography.bodyBold).foregroundStyle(colors.textPrimary)
                                Text(desc).font(DesignSystem.Typography.caption).foregroundStyle(colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: activityLevel == id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(activityLevel == id ? colors.neonGreen : colors.textTertiary)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .fill(activityLevel == id ? colors.neonGreen.opacity(0.08) : colors.backgroundElevated))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer().frame(height: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Step 5: Avoid Foods
    
    private var avoidFoodsStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                stepHeader(icon: "xmark.circle", title: "Any foods to avoid?", subtitle: "We'll make sure they never appear in your plan")
                
                FlowLayout(spacing: 8) {
                    ForEach(avoidFoods, id: \.self) { food in
                        HStack(spacing: 4) {
                            Text(food)
                            Button { avoidFoods.removeAll { $0 == food } } label: {
                                Image(systemName: "xmark.circle.fill").font(.caption2)
                            }
                        }
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(colors.neonRed)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(colors.neonRed.opacity(0.15)))
                    }
                }
                
                HStack {
                    TextField("Type a food to avoid...", text: $newAvoidFood)
                        .foregroundStyle(colors.textPrimary)
                        .onSubmit { addAvoidFood() }
                    Button("Add") { addAvoidFood() }
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(colors.neonRed)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
                
                // Quick suggestions
                Text("Common avoids:")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                FlowLayout(spacing: 8) {
                    ForEach(["Mushrooms", "Bitter gourd", "Tofu", "Paneer", "Brinjal", "Okra", "Curd", "Spicy food"], id: \.self) { food in
                        Button {
                            if !avoidFoods.contains(food) { avoidFoods.append(food) }
                        } label: {
                            Text("+ \(food)")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundStyle(colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(colors.backgroundElevated))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer().frame(height: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Helpers
    
    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(colors.neonGreen)
                .neonGlow(colors.neonGreen, intensity: 0.4)
            Text(title)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(colors.textPrimary)
            Text(subtitle)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }
    
    private func addAvoidFood() {
        let trimmed = newAvoidFood.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !avoidFoods.contains(trimmed) else { return }
        avoidFoods.append(trimmed)
        newAvoidFood = ""
    }
    
    private func saveAndComplete() {
        preferences.dietType = dietType
        preferences.preferredCuisines = Array(selectedCuisines)
        preferences.goal = goal
        preferences.mealsPerDay = mealsPerDay
        preferences.budgetLevel = budgetLevel
        preferences.activityLevel = activityLevel
        preferences.avoidFoods = avoidFoods
        preferences.isSetupComplete = true
        try? modelContext.save()
        Haptic.notification(.success)
        onComplete()
        dismiss()
    }
}
