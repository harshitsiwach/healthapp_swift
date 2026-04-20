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
    @State private var showSplash = false
    @State private var showConfetti = false
    @State private var showingSleepSheet = false
    @State private var showingStepsSheet = false
    @State private var showingActivityDetail = false
    
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
    
    // MARK: - Health Metrics from DailyLog
    
    private var todayLog: DailyLog? {
        allLogs.first { $0.date == selectedDateString }
    }
    
    private var loggedSteps: Int {
        todayLog?.steps ?? 0
    }
    
    private var loggedSleepHours: Int {
        todayLog?.sleepHours ?? 0
    }
    
    private var loggedSleepMinutes: Int {
        todayLog?.sleepMinutes ?? 0
    }
    
    private var sleepDisplay: String {
        if loggedSleepHours == 0 && loggedSleepMinutes == 0 {
            return "Tap to log"
        }
        return "\(loggedSleepHours)h \(loggedSleepMinutes)m"
    }
    
    private var stepsDisplay: String {
        if loggedSteps == 0 {
            return "Tap to log"
        }
        return "\(loggedSteps.formatted())"
    }
    
    private let stepsGoal = 10000
    
    private var stepsProgress: Double {
        guard loggedSteps > 0 else { return 0 }
        return min(Double(loggedSteps) / Double(stepsGoal), 1.0)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackground(themeManager: themeManager)
                
                // Floating ambient particles
                FloatingParticles(color: colors.neonBlue, count: 6)
                    .opacity(0.3)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        headerView
                            .padding(.top, DesignSystem.Spacing.xs)
                        
                        heartRateCard
                            .staggeredEntrance(index: 0)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            sleepCard
                                .staggeredEntrance(index: 1)
                            stepsCard
                                .staggeredEntrance(index: 2)
                        }
                        
                        activityRingsCard
                            .staggeredEntrance(index: 3)
                        
                        calorieCard
                            .staggeredEntrance(index: 4)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            hydrationCard
                                .staggeredEntrance(index: 5)
                            macrosCard
                                .staggeredEntrance(index: 6)
                        }
                        
                        quickActionsRow
                            .staggeredEntrance(index: 7)
                        
                        recentlyLoggedSection
                            .staggeredEntrance(index: 8)
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
                    let wasUnderGoal = hydrationML < hydrationGoal
                    hydrationML += added
                    hydrationDate = selectedDateString
                    Haptic.notification(.success)
                    
                    // Trigger splash
                    showSplash = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSplash = false
                    }
                    
                    // Confetti if goal reached
                    if wasUnderGoal && hydrationML >= hydrationGoal {
                        showConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showConfetti = false
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSleepSheet) {
                SleepLoggingSheet(
                    hours: loggedSleepHours,
                    minutes: loggedSleepMinutes,
                    colors: colors
                ) { hours, minutes in
                    saveSleep(hours: hours, minutes: minutes)
                }
            }
            .sheet(isPresented: $showingStepsSheet) {
                StepsLoggingSheet(
                    currentSteps: loggedSteps,
                    goal: stepsGoal,
                    colors: colors
                ) { steps in
                    saveSteps(steps)
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
                    .heartbeat(active: true)
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
    }
    
    // MARK: - Sleep Card
    
    private var sleepCard: some View {
        Button {
            Haptic.impact(.light)
            showingSleepSheet = true
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(colors.neonBlue)
                        .neonGlow(colors.neonBlue, intensity: 0.3)
                    Spacer()
                    Image(systemName: loggedSleepHours > 0 ? "pencil.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(colors.neonBlue)
                }
                
                Text(sleepDisplay)
                    .font(DesignSystem.Typography.statMedium)
                    .foregroundStyle(colors.textPrimary)
                    .contentTransition(.numericText())
                
                Text("Sleep")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
                
                // Sleep quality bars (animated from data)
                HStack(spacing: 3) {
                    let totalMinutes = loggedSleepHours * 60 + loggedSleepMinutes
                    let qualityBars = min(8, max(1, totalMinutes / 60))
                    ForEach(0..<8, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < qualityBars ? colors.neonBlue : colors.neonBlue.opacity(0.15))
                            .frame(height: CGFloat(6 + (i % 4) * 5))
                            .animation(.spring(response: 0.5).delay(Double(i) * 0.05), value: qualityBars)
                    }
                }
                .frame(height: 24)
            }
            .themedCard()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.scaleButton)
    }
    
    // MARK: - Steps Card
    
    private var stepsCard: some View {
        Button {
            Haptic.impact(.light)
            showingStepsSheet = true
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 16))
                        .foregroundStyle(colors.neonYellow)
                        .neonGlow(colors.neonYellow, intensity: 0.3)
                    Spacer()
                    Image(systemName: loggedSteps > 0 ? "pencil.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(colors.neonYellow)
                }
                
                Text(stepsDisplay)
                    .font(DesignSystem.Typography.statMedium)
                    .foregroundStyle(colors.textPrimary)
                    .contentTransition(.numericText())
                
                Text("Steps")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.neonYellow.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.neonYellow.gradient)
                            .frame(width: geo.size.width * stepsProgress)
                            .animation(.spring(response: 0.8), value: stepsProgress)
                    }
                }
                .frame(height: 6)
                
                Text(loggedSteps > 0 ? "\(Int(stepsProgress * 100))% of \(stepsGoal.formatted())" : "Set your goal")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textTertiary)
            }
            .themedCard()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.scaleButton)
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
    }
    
    // MARK: - Hydration Card (Tappable)
    
    private var hydrationCard: some View {
        let pct = Double(currentHydration) / Double(hydrationGoal)
        
        return ZStack {
            Button {
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
                            .glowPulse(colors.neonBlue)
                    }
                    
                    AnimatedWaterFill(fillPercent: min(pct, 1.0), color: colors.neonBlue)
                        .frame(width: 50, height: 80)
                    
                    Text("\(currentHydration)ml / \(hydrationGoal)ml")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                        .contentTransition(.numericText())
                }
                .themedCard()
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.scaleButton)
            
            // Splash effect on add
            SplashParticles(color: colors.neonBlue, isActive: showSplash, count: 10)
                .offset(y: -10)
            
            // Confetti when goal reached
            ConfettiView(isActive: showConfetti)
        }
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
    
    // MARK: - Save Functions
    
    private func saveSleep(hours: Int, minutes: Int) {
        if let log = todayLog {
            log.sleepHours = hours
            log.sleepMinutes = minutes
        } else {
            let log = DailyLog(date: selectedDateString, sleepHours: hours, sleepMinutes: minutes)
            modelContext.insert(log)
        }
        try? modelContext.save()
        Haptic.notification(.success)
    }
    
    private func saveSteps(_ steps: Int) {
        if let log = todayLog {
            log.steps = steps
        } else {
            let log = DailyLog(date: selectedDateString, steps: steps)
            modelContext.insert(log)
        }
        try? modelContext.save()
        Haptic.notification(.success)
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

// MARK: - Sleep Logging Sheet

struct SleepLoggingSheet: View {
    @Environment(\.dismiss) var dismiss
    let hours: Int
    let minutes: Int
    let colors: DesignSystem.ThemeColors
    let onSave: (Int, Int) -> Void
    
    @State private var selectedHours: Int
    @State private var selectedMinutes: Int
    
    init(hours: Int, minutes: Int, colors: DesignSystem.ThemeColors, onSave: @escaping (Int, Int) -> Void) {
        self.hours = hours
        self.minutes = minutes
        self.colors = colors
        self.onSave = onSave
        self._selectedHours = State(initialValue: hours)
        self._selectedMinutes = State(initialValue: minutes)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Moon icon with glow
                Image(systemName: "moon.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(colors.neonBlue)
                    .neonGlow(colors.neonBlue, intensity: 0.5)
                    .padding(.top, DesignSystem.Spacing.lg)
                
                Text("How long did you sleep?")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(colors.textPrimary)
                
                // Time pickers
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Hours picker
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Hours")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                        
                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0..<13, id: \.self) { h in
                                Text("\(h)").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(colors.backgroundElevated)
                        )
                    }
                    
                    Text(":")
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(colors.textTertiary)
                    
                    // Minutes picker
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Minutes")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                        
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(colors.backgroundElevated)
                        )
                    }
                }
                
                // Total display
                let totalMinutes = selectedHours * 60 + selectedMinutes
                Text("Total: \(totalMinutes / 60)h \(totalMinutes % 60)m")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(totalMinutes >= 420 ? colors.neonGreen : totalMinutes >= 360 ? colors.neonYellow : colors.neonRed)
                    .animation(.smooth, value: totalMinutes)
                
                // Quality indicator
                if totalMinutes > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: totalMinutes >= 420 ? "checkmark.circle.fill" : totalMinutes >= 360 ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                            .foregroundStyle(totalMinutes >= 420 ? colors.neonGreen : totalMinutes >= 360 ? colors.neonYellow : colors.neonRed)
                        Text(totalMinutes >= 420 ? "Great sleep!" : totalMinutes >= 360 ? "Could be better" : "You need more rest")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Save button
                Button {
                    onSave(selectedHours, selectedMinutes)
                    dismiss()
                } label: {
                    Text("Save Sleep")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                .fill(colors.neonBlue.gradient)
                        )
                }
                .buttonStyle(.scaleButton)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Log Sleep")
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

// MARK: - Steps Logging Sheet

struct StepsLoggingSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentSteps: Int
    let goal: Int
    let colors: DesignSystem.ThemeColors
    let onSave: (Int) -> Void
    
    @State private var stepInput: String
    @State private var selectedPreset: Int? = nil
    
    init(currentSteps: Int, goal: Int, colors: DesignSystem.ThemeColors, onSave: @escaping (Int) -> Void) {
        self.currentSteps = currentSteps
        self.goal = goal
        self.colors = colors
        self.onSave = onSave
        self._stepInput = State(initialValue: currentSteps > 0 ? "\(currentSteps)" : "")
    }
    
    let presets = [2500, 5000, 7500, 10000, 12500, 15000]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                headerSection
                inputSection
                presetsSection
                ringPreview
                Spacer()
                saveButton
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Log Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.neonYellow)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "figure.walk")
                .font(.system(size: 50))
                .foregroundStyle(colors.neonYellow)
                .neonGlow(colors.neonYellow, intensity: 0.5)
                .padding(.top, DesignSystem.Spacing.lg)
            
            Text("How many steps today?")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(colors.textPrimary)
            
            if let steps = Int(stepInput), steps > 0 {
                let pct = Double(steps) / Double(goal)
                VStack(spacing: 4) {
                    Text("\(steps.formatted())")
                        .font(DesignSystem.Typography.statLarge)
                        .foregroundStyle(colors.textPrimary)
                        .contentTransition(.numericText())
                    Text("\(Int(pct * 100))% of \(goal.formatted()) goal")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(pct >= 1.0 ? colors.neonGreen : colors.textSecondary)
                }
                .animation(.smooth, value: steps)
            }
        }
    }
    
    private var inputSection: some View {
        HStack {
            Image(systemName: "number")
                .foregroundStyle(colors.textTertiary)
            TextField("Enter steps", text: $stepInput)
                .font(DesignSystem.Typography.title2)
                .keyboardType(.numberPad)
                .foregroundStyle(colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(colors.backgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .strokeBorder(colors.cardBorder))
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Quick Add")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.md)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    presetButton(preset)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    private func presetButton(_ preset: Int) -> some View {
        let isSelected = selectedPreset == preset
        return Button {
            Haptic.selection()
            stepInput = "\(preset)"
            selectedPreset = preset
        } label: {
            Text(preset.formatted())
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(isSelected ? .white : colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(isSelected ? colors.neonYellow.opacity(0.9) : colors.backgroundElevated)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(isSelected ? colors.neonYellow : colors.cardBorder))
                )
        }
        .buttonStyle(.scaleButton)
    }
    
    @ViewBuilder
    private var ringPreview: some View {
        if let steps = Int(stepInput), steps > 0 {
            let pct = min(Double(steps) / Double(goal), 1.0)
            ActivityRing(progress: pct, color: colors.neonYellow, size: 100, lineWidth: 12)
                .padding(.top, DesignSystem.Spacing.sm)
        }
    }
    
    private var saveButton: some View {
        Button {
            if let steps = Int(stepInput), steps > 0 {
                onSave(steps)
                dismiss()
            }
        } label: {
            Text("Save Steps")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill((Int(stepInput) ?? 0) > 0 ? colors.neonYellow.gradient : colors.textTertiary.opacity(0.3).gradient)
                )
        }
        .buttonStyle(.scaleButton)
        .disabled((Int(stepInput) ?? 0) <= 0)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.lg)
    }
}
