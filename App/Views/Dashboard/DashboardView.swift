import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyLog.date, order: .reverse) private var allLogs: [DailyLog]
    
    @State private var selectedDate = Date()
    @State private var showingMealEdit: DailyLog?
    @State private var showingCamera = false
    @State private var showingMealIdeas = false
    @State private var animateCalorieRing = false
    @State private var animateMacros = false
    
    private var profile: UserProfile? { profiles.first }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private var logsForDate: [DailyLog] {
        allLogs.filter { $0.date == selectedDateString && $0.foodName != nil }
    }
    
    private var goalLogForDate: DailyLog? {
        allLogs.first { $0.date == selectedDateString && $0.goalCompleted != nil }
    }
    
    private var consumedCalories: Int {
        logsForDate.reduce(0) { $0 + $1.estimatedCalories }
    }
    
    private var consumedProtein: Double {
        logsForDate.reduce(0) { $0 + $1.proteinG }
    }
    
    private var consumedCarbs: Double {
        logsForDate.reduce(0) { $0 + $1.carbsG }
    }
    
    private var consumedFat: Double {
        logsForDate.reduce(0) { $0 + $1.fatG }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumGradientBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Header
                        headerView
                            .padding(.top, DesignSystem.Spacing.xs)
                        
                        // Weekly Calendar
                        WeeklyCalendarView(selectedDate: $selectedDate)
                        
                        // Goal Prompt (if applicable)
                        if shouldShowGoalPrompt {
                            goalPromptCard
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Main Calorie Card
                        calorieCard
                        
                        // Macro Row
                        macroRow
                        
                        // Quick Actions
                        quickActionsRow
                        
                        // Recently Logged
                        recentlyLoggedSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .sheet(item: $showingMealEdit) { meal in
                MealEditSheet(meal: meal)
            }
            .sheet(isPresented: $showingCamera) {
                FoodLoggingSheet()
            }
            .navigationDestination(isPresented: $showingMealIdeas) {
                MealIdeasView()
            }
            .onAppear {
                withAnimation(DesignSystem.Animation.spring.delay(0.3)) {
                    animateCalorieRing = true
                }
                withAnimation(DesignSystem.Animation.spring.delay(0.5)) {
                    animateMacros = true
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // App Logo
            AppLogo(size: .small)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(DesignSystem.Typography.title3)
                    .contentTransition(.numericText())
                
                Text(motivationalText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .id(motivationalText)
                    .transition(.opacity)
            }
            
            Spacer()
            
            // Streak Badge
            if let profile = profile, profile.streakCount > 0 {
                streakBadge(count: profile.streakCount)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Settings
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func streakBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
                .pulse(active: count >= 7)
            
            Text("\(count)")
                .font(DesignSystem.Typography.captionBold)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Calorie Card
    
    private var calorieCard: some View {
        Button {
            Haptic.impact(.light)
            showingMealIdeas = true
        } label: {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Progress Ring
                ZStack {
                    PremiumProgressRing(
                        progress: calorieProgress,
                        lineWidth: 14,
                        size: 160,
                        color: calorieProgress > 1.0 ? DesignSystem.Colors.error : DesignSystem.Colors.primary
                    )
                    
                    VStack(spacing: 2) {
                        AnimatedCounter(
                            value: remainingCalories,
                            font: DesignSystem.Typography.calorieNumber,
                            color: remainingCalories < 0 ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary
                        )
                        
                        Text("kcal left")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .scaleEffect(animateCalorieRing ? 1 : 0.8)
                .opacity(animateCalorieRing ? 1 : 0)
                
                // Eaten → Target
                HStack(spacing: DesignSystem.Spacing.lg) {
                    StatBlock(value: "\(consumedCalories)", label: "Eaten", color: DesignSystem.Colors.textSecondary)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .symbolEffect(.pulse)
                    
                    StatBlock(value: "\(profile?.calculatedDailyCalories ?? 2000)", label: "Target", color: DesignSystem.Colors.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .premiumCard()
        }
        .buttonStyle(.scaleButton)
    }
    
    // MARK: - Macro Row
    
    private var macroRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            macroCard(
                label: "Protein",
                consumed: consumedProtein,
                target: Double(profile?.calculatedDailyProtein ?? 125),
                color: DesignSystem.Colors.protein,
                icon: "p.circle.fill"
            )
            
            macroCard(
                label: "Carbs",
                consumed: consumedCarbs,
                target: Double(profile?.calculatedDailyCarbs ?? 250),
                color: DesignSystem.Colors.carbs,
                icon: "c.circle.fill"
            )
            
            macroCard(
                label: "Fats",
                consumed: consumedFat,
                target: Double(profile?.calculatedDailyFats ?? 56),
                color: DesignSystem.Colors.fat,
                icon: "f.circle.fill"
            )
        }
        .scaleEffect(animateMacros ? 1 : 0.9)
        .opacity(animateMacros ? 1 : 0)
    }
    
    private func macroCard(label: String, consumed: Double, target: Double, color: Color, icon: String) -> some View {
        let remaining = target - consumed
        let progress = target > 0 ? consumed / target : 0
        let isOver = consumed > target
        let hour = Calendar.current.component(.hour, from: Date())
        let isLowIntake = !isOver && consumed < target * 0.3 && hour >= 15
        
        return VStack(spacing: DesignSystem.Spacing.xs) {
            MacroPill(label: label, value: consumed, target: target, color: color)
            
            if isOver {
                Text("+\(Int(consumed - target))g over")
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.error)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignSystem.Colors.error.opacity(0.1), in: Capsule())
            } else if isLowIntake {
                Text("Low")
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignSystem.Colors.warning.opacity(0.1), in: Capsule())
            } else {
                Text("\(Int(max(remaining, 0)))g left")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .premiumCard(padding: DesignSystem.Spacing.sm)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Scan Report
            NavigationLink(destination: MedicalReportScannerView()) {
                QuickAction(icon: "doc.text.viewfinder", title: "Scan Report", color: DesignSystem.Colors.accent)
            }
            .buttonStyle(.plain)
            
            // Weekly Stats
            NavigationLink(destination: WeeklyStatsView()) {
                QuickAction(icon: "chart.bar.fill", title: "Weekly Stats", color: DesignSystem.Colors.secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Goal Prompt
    
    private var shouldShowGoalPrompt: Bool {
        guard Calendar.current.isDateInToday(selectedDate),
              let profile = profile else { return false }
        
        let components = profile.notificationTime.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return false }
        
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let isPastTime = (now.hour ?? 0) >= components[0] && (now.minute ?? 0) >= components[1]
        
        return isPastTime && goalLogForDate == nil
    }
    
    private var goalPromptCard: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Did you complete your goals today?")
                .font(DesignSystem.Typography.headline)
                .multilineTextAlignment(.center)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    Haptic.impact()
                    recordGoalCompletion(completed: false)
                } label: {
                    Text("Not yet")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(DesignSystem.Colors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.error.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                }
                
                Button {
                    Haptic.notification(.success)
                    recordGoalCompletion(completed: true)
                } label: {
                    Text("Yes! ✅")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.success.gradient, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .premiumCard()
    }
    
    // MARK: - Recently Logged
    
    private var recentlyLoggedSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Recently Logged")
                .font(DesignSystem.Typography.headline)
            
            if logsForDate.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    
                    Text("No meals logged yet")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    
                    Text("Tap + to log your first meal")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
                .premiumCard()
            } else {
                ForEach(Array(logsForDate.enumerated()), id: \.element.id) { index, log in
                    Button {
                        Haptic.selection()
                        showingMealEdit = log
                    } label: {
                        mealRow(log: log)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
    }
    
    private func mealRow(log: DailyLog) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Color indicator based on calories
            RoundedRectangle(cornerRadius: 3)
                .fill(calorieColor(for: log.estimatedCalories))
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.foodName ?? "Meal")
                    .font(DesignSystem.Typography.bodyBold)
                    .lineLimit(1)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    MacroBadge(label: "P", value: Int(log.proteinG), color: DesignSystem.Colors.protein)
                    MacroBadge(label: "C", value: Int(log.carbsG), color: DesignSystem.Colors.carbs)
                    MacroBadge(label: "F", value: Int(log.fatG), color: DesignSystem.Colors.fat)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(log.estimatedCalories)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.primary)
                
                Text("kcal")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .premiumCard(padding: DesignSystem.Spacing.xs)
    }
    
    // MARK: - Helpers
    
    private func calorieColor(for calories: Int) -> Color {
        if calories > 500 { return DesignSystem.Colors.error }
        if calories > 300 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.success
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var motivationalText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning! Let's start strong 💪" }
        if hour < 17 { return "Keep going, you're doing great! 🌟" }
        if hour < 21 { return "Almost there, finish strong! 🎯" }
        return "Great job today! Rest well 🌙"
    }
    
    private var remainingCalories: Int {
        (profile?.calculatedDailyCalories ?? 2000) - consumedCalories
    }
    
    private var calorieProgress: Double {
        let target = Double(profile?.calculatedDailyCalories ?? 2000)
        guard target > 0 else { return 0 }
        return Double(consumedCalories) / target
    }
    
    private func recordGoalCompletion(completed: Bool) {
        let log = DailyLog(date: selectedDateString, goalCompleted: completed ? 1 : 0)
        modelContext.insert(log)
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct StatBlock: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(color)
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}

struct QuickAction: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .premiumCard(padding: DesignSystem.Spacing.sm)
    }
}

struct MacroBadge: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(color)
            Text("\(value)g")
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1), in: Capsule())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scaleButton: ScaleButtonStyle { ScaleButtonStyle() }
}
