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
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerView
                        
                        // Weekly Calendar
                        WeeklyCalendarView(selectedDate: $selectedDate)
                        
                        // Goal Prompt (if applicable)
                        if shouldShowGoalPrompt {
                            goalPromptCard
                        }
                        
                        // Main Calorie Card
                        calorieCard
                        
                        // Macro Row
                        macroRow
                        
                        // Weekly Balances Button
                        NavigationLink(destination: WeeklyStatsView()) {
                            GlassCard {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundStyle(.blue)
                                    Text("Weekly Balances")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Recently Logged
                        recentlyLoggedSection
                    }
                    .padding(.horizontal, 16)
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
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.heavy)
                Text("Stay on track today")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Streak Badge
            if let profile = profile {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(profile.streakCount)")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.heavy)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.top, 8)
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
        GlassCard(material: .regularMaterial) {
            VStack(spacing: 16) {
                Text("Did you complete your goals today?")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Button {
                        recordGoalCompletion(completed: false)
                    } label: {
                        Text("Not yet")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        recordGoalCompletion(completed: true)
                    } label: {
                        Text("Yes! ✅")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Calorie Card
    
    private var calorieCard: some View {
        Button {
            showingMealIdeas = true
        } label: {
            GlassCard(material: .regularMaterial, cornerRadius: 28, padding: 24) {
                VStack(spacing: 16) {
                    CircularProgressView(
                        progress: calorieProgress,
                        lineWidth: 14,
                        size: 140,
                        progressColor: calorieProgress > 1.0 ? .red : .blue
                    )
                    .overlay {
                        VStack(spacing: 2) {
                            Text("\(remainingCalories)")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(remainingCalories < 0 ? .red : .primary)
                            Text("kcal left")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        VStack(spacing: 2) {
                            Text("\(consumedCalories)")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.heavy)
                            Text("Eaten")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("\(profile?.calculatedDailyCalories ?? 2000)")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.heavy)
                            Text("Target")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Macro Row
    
    private var macroRow: some View {
        HStack(spacing: 12) {
            macroCard(
                label: "Protein",
                consumed: consumedProtein,
                target: Double(profile?.calculatedDailyProtein ?? 125),
                color: .green,
                icon: "leaf.fill"
            )
            macroCard(
                label: "Carbs",
                consumed: consumedCarbs,
                target: Double(profile?.calculatedDailyCarbs ?? 250),
                color: .orange,
                icon: "flame.fill"
            )
            macroCard(
                label: "Fats",
                consumed: consumedFat,
                target: Double(profile?.calculatedDailyFats ?? 56),
                color: .purple,
                icon: "drop.fill"
            )
        }
    }
    
    private func macroCard(label: String, consumed: Double, target: Double, color: Color, icon: String) -> some View {
        let remaining = target - consumed
        let progress = target > 0 ? consumed / target : 0
        let isOver = consumed > target
        let hour = Calendar.current.component(.hour, from: Date())
        let isLowIntake = !isOver && consumed < target * 0.3 && hour >= 15
        
        return GlassCard(padding: 12) {
            VStack(spacing: 8) {
                MiniCircularProgress(progress: progress, size: 36, lineWidth: 3.5, color: isOver ? .red : color)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 10))
                            .foregroundStyle(color)
                    }
                
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Text("\(Int(max(remaining, 0)))g")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundStyle(isOver ? .red : .primary)
                
                if isOver {
                    Text("+\(Int(consumed - target))g over")
                        .font(.system(size: 9, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                } else if isLowIntake {
                    Text("⚠️ Low")
                        .font(.system(size: 9, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Recently Logged
    
    private var recentlyLoggedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Logged")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
            
            if logsForDate.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No meals logged yet")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("Tap + to log your first meal")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                ForEach(logsForDate, id: \.id) { log in
                    Button {
                        showingMealEdit = log
                    } label: {
                        GlassCard(padding: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(log.foodName ?? "Meal")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                    Text("P:\(Int(log.proteinG))g • C:\(Int(log.carbsG))g • F:\(Int(log.fatG))g")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(log.estimatedCalories) kcal")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.heavy)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Computed
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
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
