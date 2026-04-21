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
    @State private var showingHRVSheet = false
    @State private var showingModelBrowser = false
    @State private var showingCalorieSuggestions = false
    @State private var showingMedicalPassport = false
    
    // Hydration tracking (persisted per day)
    @AppStorage("hydration_ml") private var hydrationML: Int = 0
    @AppStorage("hydration_date") private var hydrationDate: String = ""
    
    // Simulated health data
    @State private var heartRateTimer: Timer?
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
    
    private var loggedHRV: Double {
        todayLog?.hrvMs ?? 0
    }
    
    private var loggedStress: Int {
        todayLog?.stressLevel ?? 0
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
            .sheet(isPresented: $showingHRVSheet) {
                HRVStressSheet(
                    currentHRV: loggedHRV,
                    currentStress: loggedStress
                ) { hrv, stress in
                    saveHRVStress(hrv: hrv, stress: stress)
                }
            }
            .fullScreenCover(isPresented: $showingModelBrowser) {
                HuggingFaceModelBrowser()
            }
            .sheet(isPresented: $showingCalorieSuggestions) {
                CalorieSuggestionsSheet(
                    consumed: consumedCalories,
                    target: profile?.calculatedDailyCalories ?? 2000
                )
            }
            .sheet(isPresented: $showingMedicalPassport) {
                MedicalPassportView()
            }
            .navigationDestination(isPresented: $showingMealIdeas) {
                MealIdeasView()
            }
            .onAppear {
                withAnimation(DesignSystem.Anim.spring.delay(0.1)) {
                    animateOnAppear = true
                }
                heartRateTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                    withAnimation(.smooth) {
                        heartRate = Int.random(in: 65...85)
                        pulseData.removeFirst()
                        pulseData.append(Double(heartRate) + Double.random(in: -5...5))
                    }
                }
            }
            .onDisappear {
                heartRateTimer?.invalidate()
                heartRateTimer = nil
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
        Button {
            Haptic.impact(.light)
            showingHRVSheet = true
        } label: {
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
                    
                    // HRV + Stress badges
                    if loggedHRV > 0 {
                        HStack(spacing: 6) {
                            Label("\(Int(loggedHRV))ms", systemImage: "waveform.path.ecg")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(hrvColor)
                            if loggedStress > 0 {
                                Label("\(loggedStress)/10", systemImage: "brain.head.profile")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(stressColor)
                            }
                        }
                    }
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
        .buttonStyle(.scaleButton)
    }
    
    private var hrvColor: Color {
        if loggedHRV >= 80 { return colors.neonGreen }
        if loggedHRV >= 50 { return colors.neonYellow }
        if loggedHRV >= 30 { return colors.neonOrange }
        return colors.neonRed
    }
    
    private var stressColor: Color {
        if loggedStress <= 3 { return colors.neonGreen }
        if loggedStress <= 5 { return colors.neonYellow }
        if loggedStress <= 7 { return colors.neonOrange }
        return colors.neonRed
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
        Button {
            Haptic.selection()
            showingActivityDetail = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Stacked concentric rings (Apple Fitness style)
                ZStack {
                    // Move ring (outermost, red)
                    ActivityRing(progress: moveProgress, color: colors.neonRed, size: 120, lineWidth: 14)
                    // Exercise ring (middle, blue)
                    ActivityRing(progress: exerciseProgress, color: colors.neonBlue, size: 92, lineWidth: 14)
                    // Stand ring (innermost, yellow)
                    ActivityRing(progress: standProgress, color: colors.neonYellow, size: 64, lineWidth: 14)
                }
                .frame(width: 130, height: 130)
                
                // Stats column
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    ringStat(icon: "flame.fill", label: "MOVE", value: "\(moveCal)/\(moveGoal)", unit: "kcal", color: colors.neonRed)
                    ringStat(icon: "figure.run", label: "EXERCISE", value: "\(exerciseMin)/\(exerciseGoal)", unit: "min", color: colors.neonBlue)
                    ringStat(icon: "figure.stand", label: "STAND", value: "\(standHr)/\(standGoal)", unit: "hrs", color: colors.neonYellow)
                }
            }
            .frame(maxWidth: .infinity)
            .themedCard()
        }
        .buttonStyle(.scaleButton)
        .sheet(isPresented: $showingActivityDetail) {
            ActivityDetailView(
                moveCal: moveCal, moveGoal: moveGoal,
                exerciseMin: exerciseMin, exerciseGoal: exerciseGoal,
                standHr: standHr, standGoal: standGoal
            )
        }
    }
    
    private func ringStat(icon: String, label: String, value: String, unit: String, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .tracking(0.5)
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.textPrimary)
                    Text(unit)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                }
            }
        }
    }
    
    // MARK: - Activity Ring Data
    
    private var moveCal: Int { todayLog?.estimatedCalories ?? 0 }
    private var moveGoal: Int { profile?.calculatedDailyCalories ?? 500 }
    private var moveProgress: Double { moveGoal > 0 ? min(Double(moveCal) / Double(moveGoal), 1.0) : 0 }
    
    private var exerciseMin: Int { 0 } // Will connect to HealthKit
    private var exerciseGoal: Int { 30 }
    private var exerciseProgress: Double { min(Double(exerciseMin) / Double(exerciseGoal), 1.0) }
    
    private var standHr: Int { 0 } // Will connect to HealthKit
    private var standGoal: Int { 12 }
    private var standProgress: Double { min(Double(standHr) / Double(standGoal), 1.0) }
    
    // MARK: - Calorie Card
    
    private var calorieCard: some View {
        let target = profile?.calculatedDailyCalories ?? 2000
        let remaining = target - consumedCalories
        let progress = target > 0 ? Double(consumedCalories) / Double(target) : 0
        let isUnderGoal = remaining > 200
        let isOverGoal = remaining < 0

        return Button {
            Haptic.impact(.light)
            showingCalorieSuggestions = true
        } label: {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Calories")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(colors.textSecondary)
                            
                            // Status badge
                            if isUnderGoal {
                                Label("Add meals", systemImage: "fork.knife")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.neonGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(colors.neonGreen.opacity(0.15)))
                            } else if isOverGoal {
                                Label("Burn it off", systemImage: "flame.fill")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.neonOrange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(colors.neonOrange.opacity(0.15)))
                            }
                        }
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
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(colors.textTertiary)
                    Label("Tap for \(isOverGoal ? "exercises" : "meals")", systemImage: isOverGoal ? "figure.run" : "fork.knife")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
            }
            .themedCard()
        }
        .buttonStyle(.scaleButton)
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
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                NavigationLink(destination: MealPlanView()) {
                    quickActionLabel(icon: "fork.knife.circle", title: "Meal Plans", color: colors.neonGreen)
                }
                .buttonStyle(.scaleButton)

                NavigationLink(destination: GroceryListView()) {
                    quickActionLabel(icon: "cart.fill", title: "Grocery List", color: colors.neonOrange)
                }
                .buttonStyle(.scaleButton)
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                NavigationLink(destination: FastingTrackerView()) {
                    quickActionLabel(icon: "timer", title: "Fasting", color: colors.neonPurple)
                }
                .buttonStyle(.scaleButton)
                
                NavigationLink(destination: BodyMeasurementsView()) {
                    quickActionLabel(icon: "figure", title: "Body Stats", color: colors.neonBlue)
                }
                .buttonStyle(.scaleButton)
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    Haptic.impact(.light)
                    showingMedicalPassport = true
                } label: {
                    quickActionLabel(icon: "heart.text.square.fill", title: "Medical Passport", color: colors.neonRed)
                }
                .buttonStyle(.scaleButton)
                
                NavigationLink(destination: WaterReminderView()) {
                    quickActionLabel(icon: "drop.fill", title: "Water Reminder", color: colors.neonBlue)
                }
                .buttonStyle(.scaleButton)
            }
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
    
    private func saveHRVStress(hrv: Double, stress: Int) {
        if let log = todayLog {
            log.hrvMs = hrv
            log.stressLevel = stress
        } else {
            let log = DailyLog(date: selectedDateString, hrvMs: hrv, stressLevel: stress)
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

// MARK: - Calorie Suggestions Sheet

struct CalorieSuggestionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    let consumed: Int
    let target: Int
    
    @State private var selectedTab = 0
    @State private var animateIn = false
    
    private var remaining: Int { target - consumed }
    private var isOverGoal: Bool { remaining < 0 }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Tab picker
                    Picker("Suggestions", selection: $selectedTab) {
                        Text(isOverGoal ? "Burn It Off" : "Meal Ideas").tag(0)
                        Text("Exercises").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == 0 && !isOverGoal {
                        mealSuggestions
                    } else if selectedTab == 0 && isOverGoal {
                        exerciseSuggestions
                    } else {
                        exerciseSuggestions
                    }
                }
                .padding(.bottom, 100)
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.neonGreen)
                }
            }
            .onAppear {
                selectedTab = isOverGoal ? 1 : 0
                withAnimation(.spring(response: 0.6).delay(0.1)) { animateIn = true }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: isOverGoal ? "flame.fill" : "fork.knife")
                .font(.system(size: 40))
                .foregroundStyle(isOverGoal ? colors.neonOrange : colors.neonGreen)
                .neonGlow(isOverGoal ? colors.neonOrange : colors.neonGreen, intensity: 0.5)
            
            if isOverGoal {
                Text("You're \(abs(remaining)) kcal over")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(colors.textPrimary)
                Text("Here are exercises to burn it off")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
            } else {
                Text("\(remaining) kcal remaining")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(colors.textPrimary)
                Text("Suggested meals to hit your goal")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
        }
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    private var mealSuggestions: some View {
        let meals = getMealSuggestions(for: remaining)
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Suggested Meals")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(colors.textPrimary)
                .padding(.horizontal)
            
            ForEach(Array(meals.enumerated()), id: \.offset) { _, meal in
                HStack(spacing: DesignSystem.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(colors.textPrimary)
                        Text(meal.description)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                        HStack(spacing: 8) {
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
                    }
                    Spacer()
                    Text("+\(meal.calories)")
                        .font(DesignSystem.Typography.statSmall)
                        .foregroundStyle(colors.neonGreen)
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(colors.backgroundCard)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(colors.neonGreen.opacity(0.2)))
                )
                .padding(.horizontal)
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : 30)
                .animation(.spring(response: 0.5).delay(Double(meals.firstIndex(where: { $0.name == meal.name }) ?? 0) * 0.1), value: animateIn)
            }
        }
    }
    
    private var exerciseSuggestions: some View {
        let exercises = getExerciseSuggestions(for: abs(remaining))
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Exercises to Burn \(abs(remaining)) kcal")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(colors.textPrimary)
                .padding(.horizontal)
            
            ForEach(Array(exercises.enumerated()), id: \.offset) { _, exercise in
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: exercise.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(exercise.color)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(exercise.color.opacity(0.15)))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(colors.textPrimary)
                        Text(exercise.duration)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("-\(exercise.burned) kcal")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(colors.neonOrange)
                        Text(exercise.intensity)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(exercise.color)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(colors.backgroundCard)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(exercise.color.opacity(0.2)))
                )
                .padding(.horizontal)
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : 30)
                .animation(.spring(response: 0.5).delay(Double(exercises.firstIndex(where: { $0.name == exercise.name }) ?? 0) * 0.1), value: animateIn)
            }
        }
    }
    
    private func getMealSuggestions(for calories: Int) -> [(name: String, description: String, calories: Int, protein: Int, carbs: Int, fat: Int)] {
        if calories >= 500 {
            return [
                ("Rajma Chawal", "Kidney beans with steamed rice + salad", 380, 15, 55, 10),
                ("Paneer Tikka Wrap", "Grilled paneer in whole wheat wrap", 420, 22, 40, 18),
                ("Chicken Biryani (small)", "Spiced rice with chicken + raita", 450, 25, 50, 15),
            ]
        } else if calories >= 300 {
            return [
                ("Dal Tadka + 1 Roti", "Yellow lentils with tempered spices", 280, 12, 40, 8),
                ("Vegetable Upma", "Semolina with mixed vegetables", 250, 8, 38, 9),
                ("Grilled Chicken Salad", "Mixed greens with tandoori chicken", 300, 30, 15, 12),
            ]
        } else if calories >= 150 {
            return [
                ("Fruit Chaat", "Mixed fruits with chaat masala", 120, 2, 28, 1),
                ("Roasted Chana", "Spiced roasted chickpeas", 150, 8, 22, 3),
                ("Banana + Peanut Butter", "Medium banana with 1 tbsp PB", 180, 5, 25, 8),
            ]
        } else {
            return [
                ("Green Tea + 2 Biscuits", "Light snack", 80, 1, 15, 2),
                ("A Small Handful of Almonds", "10-12 almonds", 70, 3, 2, 6),
                ("Buttermilk (Chaas)", "Spiced buttermilk", 40, 2, 4, 1),
            ]
        }
    }
    
    private func getExerciseSuggestions(for calories: Int) -> [(name: String, icon: String, color: Color, duration: String, burned: Int, intensity: String)] {
        [
            ("Walking", "figure.walk", colors.neonGreen, "\(calories / 5) min brisk walk", calories, "Low intensity"),
            ("Running", "figure.run", colors.neonRed, "\(calories / 12) min jog", calories, "High intensity"),
            ("Cycling", "bicycle", colors.neonBlue, "\(calories / 8) min cycling", calories, "Medium intensity"),
            ("Swimming", "figure.pool.swim", colors.neonBlue, "\(calories / 10) min swim", calories, "Full body"),
            ("Yoga", "figure.yoga", colors.neonPurple, "\(calories / 4) min yoga", calories, "Low + flexibility"),
            ("Dancing", "figure.dance", colors.neonYellow, "\(calories / 7) min dancing", calories, "Fun cardio"),
        ]
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    
    let moveCal: Int, moveGoal: Int
    let exerciseMin: Int, exerciseGoal: Int
    let standHr: Int, standGoal: Int
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Large stacked rings
                    ZStack {
                        ActivityRing(progress: min(Double(moveCal) / Double(moveGoal), 1.0), color: colors.neonRed, size: 240, lineWidth: 22)
                        ActivityRing(progress: min(Double(exerciseMin) / Double(exerciseGoal), 1.0), color: colors.neonBlue, size: 186, lineWidth: 22)
                        ActivityRing(progress: min(Double(standHr) / Double(standGoal), 1.0), color: colors.neonYellow, size: 132, lineWidth: 22)
                    }
                    .frame(width: 260, height: 260)
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    // Detailed stats
                    VStack(spacing: DesignSystem.Spacing.md) {
                        activityDetailRow(icon: "flame.fill", label: "MOVE", current: moveCal, goal: moveGoal, unit: "kcal", color: colors.neonRed, message: moveCal >= moveGoal ? "Goal reached! 🎉" : "\(moveGoal - moveCal) kcal to go")
                        Divider().background(colors.cardBorder)
                        activityDetailRow(icon: "figure.run", label: "EXERCISE", current: exerciseMin, goal: exerciseGoal, unit: "min", color: colors.neonBlue, message: exerciseMin >= exerciseGoal ? "Active day! 💪" : "Get moving for \(exerciseGoal - exerciseMin) more min")
                        Divider().background(colors.cardBorder)
                        activityDetailRow(icon: "figure.stand", label: "STAND", current: standHr, goal: standGoal, unit: "hrs", color: colors.neonYellow, message: standHr >= standGoal ? "Standing strong! 🧍" : "Stand up \(standGoal - standHr) more hours")
                    }
                    .themedCard()
                }
                .padding()
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.neonRed)
                }
            }
        }
    }
    
    private func activityDetailRow(icon: String, label: String, current: Int, goal: Int, unit: String, color: Color, message: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(Circle().fill(color.opacity(0.15)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .tracking(1)
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .bottom, spacing: 2) {
                    Text("\(current)")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(colors.textPrimary)
                    Text("/ \(goal) \(unit)")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                }
                Text("\(min(Int(Double(current) / Double(goal) * 100), 100))%")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(color)
            }
        }
    }
}
