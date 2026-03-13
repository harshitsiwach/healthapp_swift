import SwiftUI
import SwiftData

struct WeeklyStatsView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyLog.date, order: .reverse) private var allLogs: [DailyLog]
    
    private var profile: UserProfile? { profiles.first }
    private let calendar = Calendar.current
    
    // Week start = Monday
    private var weekStart: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return cal.date(from: components) ?? Date()
    }
    
    private var weekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
    }
    
    private var daysElapsed: Int {
        max(1, calendar.dateComponents([.day], from: weekStart, to: Date()).day! + 1)
    }
    
    private var daysRemaining: Int {
        max(1, 7 - daysElapsed)
    }
    
    private var weekLogs: [DailyLog] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let start = formatter.string(from: weekStart)
        let end = formatter.string(from: weekEnd)
        return allLogs.filter { $0.date >= start && $0.date <= end && $0.foodName != nil }
    }
    
    // Rollover pools
    private var weeklyCalorieTarget: Int { (profile?.calculatedDailyCalories ?? 2000) * 7 }
    private var weeklyCarbTarget: Int { (profile?.calculatedDailyCarbs ?? 250) * 7 }
    private var weeklyFatTarget: Int { (profile?.calculatedDailyFats ?? 56) * 7 }
    
    private var consumedCalories: Int { weekLogs.reduce(0) { $0 + $1.estimatedCalories } }
    private var consumedCarbs: Double { weekLogs.reduce(0.0) { $0 + $1.carbsG } }
    private var consumedFat: Double { weekLogs.reduce(0.0) { $0 + $1.fatG } }
    private var consumedProtein: Double { weekLogs.reduce(0.0) { $0 + $1.proteinG } }
    
    private var remainingCalories: Int { weeklyCalorieTarget - consumedCalories }
    private var remainingCarbs: Int { weeklyCarbTarget - Int(consumedCarbs) }
    private var remainingFat: Int { weeklyFatTarget - Int(consumedFat) }
    
    private var adjustedDailyCalories: Int { max(0, remainingCalories / daysRemaining) }
    private var adjustedDailyCarbs: Int { max(0, remainingCarbs / daysRemaining) }
    private var adjustedDailyFat: Int { max(0, remainingFat / daysRemaining) }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Week info
                    GlassCard(padding: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("This Week")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                Text("\(formatDate(weekStart)) — \(formatDate(weekEnd))")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Day \(daysElapsed)/7")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.heavy)
                                Text("\(daysRemaining) remaining")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Remaining Pools
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Pool Remaining")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        
                        HStack(spacing: 12) {
                            poolCard("Calories", remaining: remainingCalories, unit: "kcal", color: .blue)
                            poolCard("Carbs", remaining: remainingCarbs, unit: "g", color: .orange)
                            poolCard("Fats", remaining: remainingFat, unit: "g", color: .purple)
                        }
                    }
                    
                    // Protein (resets daily)
                    GlassCard {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Protein (Daily)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                Text("Resets each day — does not roll over")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(profile?.calculatedDailyProtein ?? 125)g")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.heavy)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    // Adjusted Targets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Adjusted Daily Target")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        Text("To get back on track for the remaining \(daysRemaining) day(s)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            adjustedCard("Calories", value: adjustedDailyCalories, unit: "kcal", original: profile?.calculatedDailyCalories ?? 2000, color: .blue)
                            adjustedCard("Carbs", value: adjustedDailyCarbs, unit: "g", original: profile?.calculatedDailyCarbs ?? 250, color: .orange)
                            adjustedCard("Fats", value: adjustedDailyFat, unit: "g", original: profile?.calculatedDailyFats ?? 56, color: .purple)
                        }
                    }
                    
                    // Insights
                    insightsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Weekly Stats")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Components
    
    private func poolCard(_ label: String, remaining: Int, unit: String, color: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(spacing: 6) {
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("\(remaining)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundStyle(remaining < 0 ? .red : color)
                Text(unit)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func adjustedCard(_ label: String, value: Int, unit: String, original: Int, color: Color) -> some View {
        let diff = value - original
        return GlassCard(padding: 14) {
            VStack(spacing: 6) {
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                if diff != 0 {
                    Text(diff > 0 ? "+\(diff)" : "\(diff)")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(diff > 0 ? .red : .green)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var insightsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Insights")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
                
                ForEach(generateInsights(), id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(insight)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private func generateInsights() -> [String] {
        var insights: [String] = []
        
        let extraCalories = consumedCalories - ((profile?.calculatedDailyCalories ?? 2000) * daysElapsed)
        if extraCalories > 200 {
            insights.append("You've had \(extraCalories) kcal extra this week. Consider reducing portion sizes.")
        } else if extraCalories < -300 {
            insights.append("You're \(abs(extraCalories)) kcal under your target. Make sure you're eating enough.")
        } else {
            insights.append("Great job! You're staying close to your calorie target this week.")
        }
        
        let avgDailyProtein = consumedProtein / Double(daysElapsed)
        if avgDailyProtein < Double(profile?.calculatedDailyProtein ?? 125) * 0.7 {
            insights.append("Your protein intake is low. Add paneer, dal, or eggs to your meals.")
        }
        
        if daysElapsed >= 3 && consumedCalories > 0 {
            insights.append("Adjusted targets account for rollover. Stick to them to finish the week on track.")
        }
        
        return insights
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
