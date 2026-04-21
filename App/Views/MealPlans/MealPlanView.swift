import SwiftUI
import SwiftData

// MARK: - Meal Plan View

struct MealPlanView: View {
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    @Query private var allPreferences: [UserMealPreferences]
    
    @State private var weeklyPlan: [MealPlan] = []
    @State private var selectedDay = 0
    @State private var showingSetup = false
    @State private var animateIn = false
    
    private var preferences: UserMealPreferences? { allPreferences.first }
    
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        ScrollView {
            if preferences?.isSetupComplete != true {
                notSetupView
            } else {
                mealPlanContent
            }
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSetup = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(colors.neonGreen)
                }
            }
        }
        .sheet(isPresented: $showingSetup) {
            MealPlanSetupView {
                regeneratePlan()
            }
        }
        .onAppear {
            if preferences?.isSetupComplete == true && weeklyPlan.isEmpty {
                regeneratePlan()
            }
            withAnimation(.spring(response: 0.6).delay(0.1)) { animateIn = true }
        }
    }
    
    // MARK: - Not Setup View
    
    private var notSetupView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(colors.neonGreen)
                .neonGlow(colors.neonGreen, intensity: 0.5)
            
            Text("Personalized Meal Plans")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(colors.textPrimary)
            
            Text("Tell us your preferences and we'll create a weekly meal plan tailored just for you — vegetarian or non-veg, your favorite cuisines, and your budget.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Button {
                showingSetup = true
            } label: {
                Text("Set Up My Meal Plan")
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonGreen.gradient))
            }
            .buttonStyle(.scaleButton)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Text("The app learns from your eating habits and improves suggestions over time")
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Meal Plan Content
    
    private var mealPlanContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Day selector
            daySelector
            
            // Today's plan
            if selectedDay < weeklyPlan.count {
                let plan = weeklyPlan[selectedDay]
                
                // Summary card
                daySummaryCard(plan: plan)
                
                // Meals
                ForEach(Array(plan.meals.enumerated()), id: \.offset) { idx, meal in
                    mealCard(meal: meal)
                        .opacity(animateIn ? 1 : 0)
                        .offset(x: animateIn ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(Double(idx) * 0.1), value: animateIn)
                }
            }
            
            // Regenerate button
            Button {
                Haptic.impact(.light)
                regeneratePlan()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate Plan")
                }
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.neonGreen)
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
            .buttonStyle(.scaleButton)
            .padding(.top)
        }
        .padding()
        .padding(.bottom, 100)
    }
    
    // MARK: - Day Selector
    
    private var daySelector: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { i in
                Button {
                    Haptic.selection()
                    withAnimation(.spring(response: 0.3)) { selectedDay = i }
                } label: {
                    VStack(spacing: 4) {
                        Text(days[i])
                            .font(DesignSystem.Typography.captionBold)
                        if i < weeklyPlan.count {
                            Text("\(weeklyPlan[i].totalCalories)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .monospacedDigit()
                        }
                    }
                    .foregroundStyle(selectedDay == i ? .white : colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(selectedDay == i ? colors.neonGreen : colors.backgroundElevated)
                    )
                }
                .buttonStyle(.scaleButton)
            }
        }
    }
    
    // MARK: - Day Summary
    
    private func daySummaryCard(plan: MealPlan) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.day)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(colors.textPrimary)
                Text("\(plan.meals.count) meals planned")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
            Spacer()
            
            macroPill(value: plan.totalCalories, label: "kcal", color: colors.neonOrange)
            macroPill(value: plan.totalProtein, label: "P", color: colors.protein)
            macroPill(value: plan.totalCarbs, label: "C", color: colors.carbs)
            macroPill(value: plan.totalFat, label: "F", color: colors.fat)
        }
        .themedCard()
    }
    
    private func macroPill(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(colors.textTertiary)
        }
    }
    
    // MARK: - Meal Card
    
    private func mealCard(meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                // Meal type badge
                Text(meal.type.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(mealTypeColor(meal.type))
                    .tracking(0.5)
                
                if meal.isVeg {
                    Text("VEG")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.neonGreen)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().strokeBorder(colors.neonGreen, lineWidth: 1))
                }
                
                Spacer()
                
                Label(meal.prepTime, systemImage: "clock")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textTertiary)
            }
            
            Text(meal.name)
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(colors.textPrimary)
            
            Text(meal.description)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
            
            HStack(spacing: 12) {
                Label("\(meal.calories) kcal", systemImage: "flame")
                    .foregroundStyle(colors.neonOrange)
                Label("P: \(meal.protein)g", systemImage: "p.circle")
                    .foregroundStyle(colors.protein)
                Label("C: \(meal.carbs)g", systemImage: "c.circle")
                    .foregroundStyle(colors.carbs)
                Label("F: \(meal.fat)g", systemImage: "f.circle")
                    .foregroundStyle(colors.fat)
            }
            .font(DesignSystem.Typography.caption2)
            
            // Ingredients
            if !meal.ingredients.isEmpty {
                Text(meal.ingredients.joined(separator: " · "))
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(colors.backgroundCard)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .strokeBorder(mealTypeColor(meal.type).opacity(0.2)))
        )
    }
    
    private func mealTypeColor(_ type: String) -> Color {
        switch type {
        case "Breakfast": return colors.neonYellow
        case "Lunch": return colors.neonBlue
        case "Dinner": return colors.neonPurple
        case "Snack": return colors.neonOrange
        default: return colors.textSecondary
        }
    }
    
    // MARK: - Generate
    
    private func regeneratePlan() {
        guard let prefs = preferences else { return }
        weeklyPlan = MealPlanEngine.generateWeeklyPlan(preferences: prefs)
    }
}
