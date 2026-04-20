import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyLog.date, order: .reverse) private var allLogs: [DailyLog]
    @StateObject private var themeManager = ThemeManager()
    
    @State private var selectedDate = Date()
    @State private var showingMealEdit: DailyLog?
    @State private var showingCamera = false
    @State private var showingMealIdeas = false
    @State private var animateOnAppear = false
    @State private var showingWaterSheet = false
    
    // Hydration tracking (persisted per day)
    @AppStorage("hydration_ml") private var hydrationML: Int = 0
    @AppStorage("hydration_date") private var hydrationDate: String = ""
    
    // Simulated health data
    @State private var heartRate = 72
    @State private var pulseData: [Double] = [68, 70, 72, 69, 71, 73, 70, 68, 72, 74, 71, 69, 73, 72, 70, 71, 73, 72, 70, 68]
    
    private let hydrationGoal = 2000 // ml
    
    private var colors: DesignSystem.ThemeColors {
        DesignSystem.ThemeColors(isDark: themeManager.isDark)
    }
    
    private var profile: UserProfile? { profiles.first }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private var currentHydration: Int {
        let today = selectedDateString
        if hydrationDate != today {
            DispatchQueue.main.async {
                hydrationML = 0
                hydrationDate = today
            }
            return 0
        }
        return hydrationML
    }
    
    private var logsForDate: [DailyLog] {
        allLogs.filter { $0.date == selectedDateString && $0.foodName != nil }
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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackground(themeManager: themeManager)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        headerView
                            .padding(.top, DesignSystem.Spacing.xs)
                        
                        heartRateCard
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            sleepCard
                            stepsCard
                        }
                        
                        activityRingsCard
                        
                        calorieCard
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            hydrationCard
                            macrosCard
                        }
                        
                        quickActionsRow
                        
                        recentlyLoggedSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, 120)
                }
            }
            .environment(\.theme, colors)
            .preferredColorScheme(themeManager.colorScheme)
            .sheet(item: $showingMealEdit) { meal in
                MealEditSheet(meal: meal)
            }
            .sheet(isPresented: $showingCamera) {
                FoodLoggingSheet()
            }
            .sheet(isPresented: $showingWaterSheet) {
                WaterIntakeSheet(
                    currentML: hydrationML,
                    goal: hydrationGoal,
                    colors: colors
                ) { added in
                    hydrationML += added
                    hydrationDate = selectedDateString
                    Haptic.notification(.success)
                }
            }
            .navigationDestination(isPresented: $showingMealIdeas) {
                MealIdeasView()
            }
            .onAppear {
                withAnimation(DesignSystem.Anim.spring.delay(0.1)) {
                    animateOnAppear = true
                }
                Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                    withAnimation(.smooth) {
                        heartRate = Int.random(in: 65...85)
                        pulseData.removeFirst()
                        pulseData.append(Double(heartRate) + Double.random(in: -5...5))
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(colors.textPrimary)
                Text(motivationalText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
            
            Spacer()
            
            // Streak
            if let profile = profile, profile.streakCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(colors.neonOrange)
                    Text("\(profile.streakCount)")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(colors.neonOrange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(colors.neonOrange.opacity(0.15))
                        .overlay(Capsule().strokeBorder(colors.neonOrange.opacity(0.3)))
                )
            }
            
            // Theme Toggle
            Button {
                Haptic.selection()
                themeManager.toggle()
            } label: {
                Image(systemName: themeManager.isDark ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager.isDark ? colors.neonYellow : colors.neonPurple)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(colors.backgroundCard)
                            .overlay(Circle().strokeBorder(colors.cardBorder))
                    )
            }
            .buttonStyle(.plain)
            
            // Settings
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(colors.backgroundCard)
                            .overlay(Circle().strokeBorder(colors.cardBorder))
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Heart Rate Card
    
    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(colors.neonRed)
                    .neonGlow(colors.neonRed, intensity: 0.4)
                Text("Heart Rate")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(colors.textSecondary)
                Spacer()
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.neonRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(colors.neonRed.opacity(0.15)))
            }
            
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xs) {
                Text("\(heartRate)")
                    .font(DesignSystem.Typography.heartRate)
                    .foregroundStyle(colors.textPrimary)
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textTertiary)
                    .padding(.bottom, 8)
            }
            
            PulseLine(dataPoints: pulseData, color: colors.neonRed)
                .frame(height: 60)
        }
        .themedCard()
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 20)
    }
    
    // MARK: - Sleep Card
    
    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "moon.fill")
                .font(.system(size: 16))
                .foregroundStyle(colors.neonBlue)
                .neonGlow(colors.neonBlue, intensity: 0.3)
            Text("7h 42m")
                .font(DesignSystem.Typography.statMedium)
                .foregroundStyle(colors.textPrimary)
            Text("Sleep")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
            HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < 6 ? colors.neonBlue : colors.neonBlue.opacity(0.2))
                        .frame(height: CGFloat(8 + i * 2))
                }
            }
            .frame(height: 24)
        }
        .themedCard()
        .frame(maxWidth: .infinity)
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 30)
    }
    
    // MARK: - Steps Card
    
    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "figure.walk")
                .font(.system(size: 16))
                .foregroundStyle(colors.neonYellow)
                .neonGlow(colors.neonYellow, intensity: 0.3)
            Text("8,432")
                .font(DesignSystem.Typography.statMedium)
                .foregroundStyle(colors.textPrimary)
            Text("Steps")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colors.neonYellow.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colors.neonYellow.gradient)
                        .frame(width: geo.size.width * 0.84)
                }
            }
            .frame(height: 6)
            Text("84% of 10k")
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(colors.textTertiary)
        }
        .themedCard()
        .frame(maxWidth: .infinity)
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 30)
    }
    
    // MARK: - Activity Rings
    
    private var activityRingsCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Activity")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: DesignSystem.Spacing.xl) {
                activityRingStat(label: "Move", value: "390/500", progress: 0.78, color: colors.neonRed)
                activityRingStat(label: "Exercise", value: "26/40", progress: 0.65, color: colors.neonBlue)
                activityRingStat(label: "Stand", value: "9/12", progress: 0.90, color: colors.neonYellow)
            }
            .frame(maxWidth: .infinity)
        }
        .themedCard()
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 30)
    }
    
    private func activityRingStat(label: String, value: String, progress: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            ActivityRing(progress: progress, color: color, size: 80, lineWidth: 10)
            VStack(spacing: 2) {
                Text(label)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textSecondary)
                Text(value)
                    .font(DesignSystem.Typography.statSmall)
                    .foregroundStyle(color)
            }
        }
    }
    
    // MARK: - Calorie Card
    
    private var calorieCard: some View {
        let target = profile?.calculatedDailyCalories ?? 2000
        let remaining = target - consumedCalories
        let progress = target > 0 ? Double(consumedCalories) / Double(target) : 0
        
        return VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.textSecondary)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(consumedCalories)")
                            .font(DesignSystem.Typography.statLarge)
                            .foregroundStyle(colors.textPrimary)
                            .contentTransition(.numericText())
                        Text("/ \(target) kcal")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textTertiary)
                            .padding(.bottom, 8)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Net")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                    Text("\(remaining)")
                        .font(DesignSystem.Typography.statMedium)
                        .foregroundStyle(remaining > 0 ? colors.neonGreen : colors.neonRed)
                        .contentTransition(.numericText())
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colors.neonGreen.opacity(0.12))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: progress > 1.0
                                ? [colors.neonRed, colors.neonOrange]
                                : [colors.neonGreen, colors.neonBlue],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(progress, 1.0))
                        .animation(.spring(response: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Label("Intake: \(consumedCalories) kcal", systemImage: "arrow.down.circle.fill")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.neonGreen)
                Spacer()
                Label("Burned: 420 kcal", systemImage: "flame.fill")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.neonOrange)
            }
        }
        .themedCard()
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 30)
    }
    
    // MARK: - Hydration Card (Tappable)
    
    private var hydrationCard: some View {
        let pct = Double(currentHydration) / Double(hydrationGoal)
        
        return Button {
            Haptic.impact(.light)
            showingWaterSheet = true
        } label: {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Hydration")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(colors.neonBlue)
                }
                
                HydrationBeaker(fillPercent: min(pct, 1.0), color: colors.neonBlue)
                    .frame(width: 50, height: 80)
                
                Text("\(currentHydration)ml / \(hydrationGoal)ml")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textTertiary)
            }
            .themedCard()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.scaleButton)
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 30)
    }
    
    // MARK: - Macros Card
    
    private var macrosCard: some View {
        let proteinTarget = Double(profile?.calculatedDailyProtein ?? 125)
        let carbsTarget = Double(profile?.calculatedDailyCarbs ?? 250)
        let fatTarget = Double(profile?.calculatedDailyFats ?? 56)
        
        return VStack(spacing: DesignSystem.Spacing.xs) {
            macroBar(label: "Protein", value: consumedProtein, target: proteinTarget, color: colors.protein)
            macroBar(label: "Carbs", value: consumedCarbs, target: carbsTarget, color: colors.carbs)
            macroBar(label: "Fat", value: consumedFat, target: fatTarget, color: colors.fat)
        }
        .themedCard()
        .frame(maxWidth: .infinity)
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 30)
    }
    
    private func macroBar(label: String, value: Double, target: Double, color: Color) -> some View {
        let pct = target > 0 ? min(value / target, 1.0) : 0
        return VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
                Spacer()
                Text("\(Int(value))/\(Int(target))g")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 5)
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            NavigationLink(destination: MedicalReportScannerView()) {
                quickActionLabel(icon: "doc.text.viewfinder", title: "Scan Report", color: colors.neonPurple)
            }
            .buttonStyle(.scaleButton)
            
            NavigationLink(destination: WeeklyStatsView()) {
                quickActionLabel(icon: "chart.bar.fill", title: "Weekly Stats", color: colors.neonBlue)
            }
            .buttonStyle(.scaleButton)
        }
    }
    
    private func quickActionLabel(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .themedCard(padding: DesignSystem.Spacing.sm)
    }
    
    // MARK: - Recently Logged
    
    private var recentlyLoggedSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Recently Logged")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(colors.textPrimary)
            
            if logsForDate.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(colors.textTertiary)
                    Text("No meals logged yet")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.textSecondary)
                    Text("Tap + to log your first meal")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
                .themedCard()
            } else {
                ForEach(Array(logsForDate.enumerated()), id: \.element.id) { _, log in
                    Button {
                        Haptic.selection()
                        showingMealEdit = log
                    } label: {
                        mealRow(log: log)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func mealRow(log: DailyLog) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(calorieColor(for: log.estimatedCalories))
                .frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(log.foodName ?? "Meal")
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(colors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    macroBadge("P", Int(log.proteinG), colors.protein)
                    macroBadge("C", Int(log.carbsG), colors.carbs)
                    macroBadge("F", Int(log.fatG), colors.fat)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(log.estimatedCalories)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(colors.neonOrange)
                Text("kcal")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textTertiary)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .themedCard(padding: DesignSystem.Spacing.xs)
    }
    
    private func macroBadge(_ label: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label).font(DesignSystem.Typography.caption2).foregroundStyle(color)
            Text("\(value)g").font(DesignSystem.Typography.caption2).foregroundStyle(colors.textTertiary)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(color.opacity(0.12), in: Capsule())
    }
    
    // MARK: - Helpers
    
    private func calorieColor(for calories: Int) -> Color {
        if calories > 500 { return colors.neonRed }
        if calories > 300 { return colors.neonOrange }
        return colors.neonGreen
    }
    
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: selectedDate)
    }
    
    private var motivationalText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning! Let's start strong" }
        if hour < 17 { return "Keep going, you're doing great" }
        if hour < 21 { return "Almost there, finish strong" }
        return "Great job today! Rest well"
    }
}

// MARK: - Water Intake Sheet

struct WaterIntakeSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentML: Int
    let goal: Int
    let colors: DesignSystem.ThemeColors
    let onAdd: (Int) -> Void
    
    @State private var customAmount: String = ""
    
    let presets = [150, 250, 350, 500, 750, 1000]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Current status
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("\(currentML)ml")
                        .font(DesignSystem.Typography.statLarge)
                        .foregroundStyle(colors.neonBlue)
                    Text("of \(goal)ml goal")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colors.neonBlue.opacity(0.12))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colors.neonBlue.gradient)
                                .frame(width: geo.size.width * min(Double(currentML) / Double(goal), 1.0))
                        }
                    }
                    .frame(height: 8)
                }
                .themedCard()
                
                // Quick add buttons
                Text("Quick Add")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(presets, id: \.self) { amount in
                        Button {
                            Haptic.impact(.light)
                            onAdd(amount)
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: amount <= 250 ? "drop.fill" : amount <= 500 ? "drop.halffull" : "drop")
                                    .font(.system(size: 24))
                                    .foregroundStyle(colors.neonBlue)
                                Text("\(amount)ml")
                                    .font(DesignSystem.Typography.bodyBold)
                                    .foregroundStyle(colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .themedCard()
                        }
                        .buttonStyle(.scaleButton)
                    }
                }
                
                // Custom amount
                HStack(spacing: DesignSystem.Spacing.sm) {
                    TextField("Custom (ml)", text: $customAmount)
                        .font(DesignSystem.Typography.body)
                        .keyboardType(.numberPad)
                        .padding(DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(colors.backgroundElevated)
                                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .strokeBorder(colors.cardBorder))
                        )
                        .foregroundStyle(colors.textPrimary)
                    
                    Button {
                        if let amount = Int(customAmount), amount > 0 {
                            Haptic.notification(.success)
                            onAdd(amount)
                            dismiss()
                        }
                    } label: {
                        Text("Add")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(colors.neonBlue.gradient)
                            )
                    }
                    .buttonStyle(.scaleButton)
                    .disabled(Int(customAmount) == nil)
                    .opacity(Int(customAmount) != nil ? 1.0 : 0.5)
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Water Intake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.neonBlue)
                }
            }
        }
    }
}
