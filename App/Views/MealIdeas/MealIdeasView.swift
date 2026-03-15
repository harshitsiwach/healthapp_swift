import SwiftUI
import SwiftData

struct MealIdeasView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyLog.date, order: .reverse) private var allLogs: [DailyLog]
    
    @StateObject private var viewModel = MealIdeasViewModel()
    
    @State private var mealType = "Full Meal"
    @State private var budget = "Moderate"
    
    private var profile: UserProfile? { profiles.first }
    
    private var remainingCalories: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let consumed = allLogs.filter { $0.date == today && $0.foodName != nil }.reduce(0) { $0 + $1.estimatedCalories }
        return max(0, (profile?.calculatedDailyCalories ?? 2000) - consumed)
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Filters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal Type")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                filterChip("Full Meal", selected: mealType == "Full Meal") { mealType = "Full Meal" }
                                filterChip("Simple Prep", selected: mealType == "Simple Prep") { mealType = "Simple Prep" }
                            }
                        }
                        
                        Text("Budget")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                filterChip("Low", selected: budget == "Low") { budget = "Low" }
                                filterChip("Moderate", selected: budget == "Moderate") { budget = "Moderate" }
                                filterChip("High", selected: budget == "High") { budget = "High" }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Remaining calories info
                    GlassCard(padding: 12) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(remainingCalories) kcal remaining today")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    
                    // Results
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Finding meals for you...")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    } else if let error = viewModel.error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(viewModel.meals) { meal in
                            mealCard(meal)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Meal Ideas")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: mealType) { _, _ in fetchMeals() }
        .onChange(of: budget) { _, _ in fetchMeals() }
        .onAppear { fetchMeals() }
    }
    
    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) { action() }
        }) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(selected ? .bold : .medium)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if #available(iOS 26, *) {
                            Capsule().fill(.clear).glassEffect(selected ? .regular.tint(.blue).interactive() : .regular.interactive(), in: .capsule)
                        } else {
                            Capsule().fill(selected ? AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(.ultraThinMaterial))
                        }
                    }
                )
                .foregroundStyle(selected ? .white : .primary)
                .overlay(Capsule().stroke(selected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.05 : 1.0)
    }
    
    private func mealCard(_ meal: MealRecommendation) -> some View {
        GlassCard(material: .regularMaterial) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("👨‍🍳")
                        .font(.title2)
                    Text(meal.name)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(meal.calories) kcal")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(.blue)
                }
                
                Text(meal.description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                HStack(spacing: 8) {
                    macroPill("P: \(Int(meal.protein))g", color: .green)
                    macroPill("C: \(Int(meal.carbs))g", color: .orange)
                    macroPill("F: \(Int(meal.fat))g", color: .purple)
                }
            }
        }
    }
    
    private func macroPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1), in: Capsule())
    }
    
    private func fetchMeals() {
        guard let profile = profile else { return }
        viewModel.fetchMeals(
            remainingCalories: remainingCalories,
            goal: profile.goal,
            dietaryPreference: profile.dietaryPreference,
            mealType: mealType,
            budget: budget
        )
    }
}
