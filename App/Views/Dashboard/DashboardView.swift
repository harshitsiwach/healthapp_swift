import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyLog.date, order: .reverse) private var allLogs: [DailyLog]
    @StateObject private var themeManager = ThemeManager()
    
    @State private var selectedDate = Date()
    @State private var showingMealEdit: DailyLog?
    @State private var showingCamera = false
    @State private var showingWaterSheet = false
    @State private var showSplash = false
    @State private var showConfetti = false
    
    private var colors: DesignSystem.ThemeColors {
        DesignSystem.ThemeColors(isDark: themeManager.isDark)
    }
    
    private var profile: UserProfile? { profiles.first }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private var todayLog: DailyLog? {
        allLogs.first { $0.date == selectedDateString }
    }
    
    private var logsForDate: [DailyLog] {
        allLogs.filter { $0.date == selectedDateString && $0.foodName != nil }
    }
    
    private var currentHydration: Int {
        todayLog?.waterML ?? 0
    }
    
    
    // MARK: - Computed Totals
    private var consumedCalories: Int { logsForDate.reduce(0) { $0 + $1.estimatedCalories } }
    private var consumedProtein: Double { logsForDate.reduce(0) { $0 + $1.proteinG } }
    private var consumedCarbs: Double { logsForDate.reduce(0) { $0 + $1.carbsG } }
    private var consumedFat: Double { logsForDate.reduce(0) { $0 + $1.fatG } }
    
    private var calorieTarget: Int { profile?.calculatedDailyCalories ?? 2000 }
    private var proteinTarget: Int { profile?.calculatedDailyProtein ?? 150 }
    private var carbsTarget: Int { profile?.calculatedDailyCarbs ?? 250 }
    private var fatTarget: Int { profile?.calculatedDailyFats ?? 70 }
    private var burnTarget: Int { profile?.burnTarget ?? 500 }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerView
                            .padding(.top, 10)
                        
                        // 1. Calories Circle Bar & Macros
                        nutritionSection
                        
                        // 2. Weekly Calories Bars
                        weeklyMacrosSection
                        
                        // 3 & 4. Hydration & Scan
                        hydrationAndScanSection
                        
                        // 5. Steps & Activity Rings
                        activitySection
                        
                        // 6. Recently Logged
                        recentlyLoggedSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $showingMealEdit) { meal in
                MealEditSheet(meal: meal)
            }
            .sheet(isPresented: $showingCamera) {
                FoodLoggingSheet()
            }
            .sheet(isPresented: $showingWaterSheet) {
                WaterIntakeSheet(
                    currentML: currentHydration,
                    goal: 2000
                ) { added in
                    addWater(added)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                if let profile = profile, profile.streakCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(colors.neonOrange)
                        Text("\(profile.streakCount) Day Streak")
                            .fontWeight(.bold)
                            .foregroundStyle(colors.neonOrange)
                    }
                }
            }
            
            Spacer()
            
            Button {
                themeManager.toggle()
                Haptic.selection()
            } label: {
                Image(systemName: themeManager.isDark ? "sun.max.fill" : "moon.fill")
                    .font(.title3)
                    .foregroundStyle(themeManager.isDark ? colors.neonYellow : colors.neonPurple)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
    }
    
    private var nutritionSection: some View {
        HStack(spacing: 30) {
            // Big Calories Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 16)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(Double(consumedCalories) / Double(calorieTarget), 1.0)))
                    .stroke(
                        AngularGradient(colors: [colors.neonBlue, colors.neonPurple], center: .center),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(consumedCalories)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text("/ \(calorieTarget)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("kcal")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            
            // 3 Small Circles
            VStack(spacing: 12) {
                smallMacroCircle(title: "P", current: consumedProtein, target: Double(proteinTarget), color: colors.neonGreen)
                smallMacroCircle(title: "C", current: consumedCarbs, target: Double(carbsTarget), color: colors.neonOrange)
                smallMacroCircle(title: "F", current: consumedFat, target: Double(fatTarget), color: colors.neonPurple)
            }
        }
    }
    
    private func smallMacroCircle(title: String, current: Double, target: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(min(current / target, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                Text("\(Int(current))g")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var weeklyMacrosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Macros")
                .font(.headline)
            
            if #available(iOS 17.0, *) {
                Chart(weeklyMacroData) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Grams", item.grams)
                    )
                    .foregroundStyle(by: .value("Macro", item.macro))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale([
                    "Protein": colors.neonGreen,
                    "Carbs": colors.neonOrange,
                    "Fat": colors.neonPurple
                ])
                .frame(height: 200)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
            }
        }
    }
    
    private struct WeeklyMacroItem: Identifiable {
        let id = UUID()
        let day: String
        let macro: String
        let grams: Double
    }
    
    private var weeklyMacroData: [WeeklyMacroItem] {
        let calendar = Calendar.current
        let today = Date()
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var weekStart = calendar.startOfDay(for: today)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: weekStart) ?? weekStart
        
        var data: [WeeklyMacroItem] = []
        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? today
            let dateStr = formatter.string(from: date)
            let logs = allLogs.filter { $0.date == dateStr && $0.foodName != nil }
            
            let p = logs.reduce(0) { $0 + $1.proteinG }
            let c = logs.reduce(0) { $0 + $1.carbsG }
            let f = logs.reduce(0) { $0 + $1.fatG }
            
            let dayName = dayNames[offset]
            data.append(WeeklyMacroItem(day: dayName, macro: "Protein", grams: p))
            data.append(WeeklyMacroItem(day: dayName, macro: "Carbs", grams: c))
            data.append(WeeklyMacroItem(day: dayName, macro: "Fat", grams: f))
        }
        return data
    }
    
    private var hydrationAndScanSection: some View {
        HStack(spacing: 20) {
            // Water Circle
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(colors.neonBlue.opacity(0.2), lineWidth: 2)
                    
                    WaterWaveCircle(fill: Double(currentHydration) / 2000.0, color: colors.neonBlue)
                        .clipShape(Circle())
                    
                    VStack(spacing: 0) {
                        Text("\(currentHydration)")
                            .font(.title2)
                            .fontWeight(.black)
                        Text("ml")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
                .frame(width: 100, height: 100)
                
                Text("Hydration")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .onTapGesture {
                showingWaterSheet = true
            }
            
            Spacer()
            
            // Scan Button
            Button {
                showingCamera = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 32))
                        .foregroundStyle(colors.neonBlue)
                    Text("Scan Barcode")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var activitySection: some View {
        HStack(spacing: 30) {
            // Steps Circle
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(Double(todayLog?.steps ?? 0) / 10000.0, 1.0)))
                        .stroke(colors.neonYellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(todayLog?.steps ?? 0)")
                            .font(.headline)
                            .fontWeight(.black)
                        Image(systemName: "shoeprints.fill")
                            .font(.caption2)
                    }
                }
                .frame(width: 80, height: 80)
                
                Text("Steps")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            // 3 Rings: Move, Exercise, Stand
            VStack(spacing: 12) {
                activityMiniRing(title: "Move", color: colors.neonRed, progress: Double(consumedCalories) / Double(burnTarget))
                activityMiniRing(title: "Exercise", color: colors.neonGreen, progress: 0.5) // Placeholder
                activityMiniRing(title: "Stand", color: colors.neonBlue, progress: 0.8) // Placeholder
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func activityMiniRing(title: String, color: Color, progress: Double) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)
            
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
            
            Spacer()
        }
    }
    
    private var recentlyLoggedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently Logged")
                .font(.headline)
            
            if logsForDate.isEmpty {
                Text("No food logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(logsForDate) { log in
                        Button {
                            showingMealEdit = log
                        } label: {
                            HStack(spacing: 16) {
                                if let uri = log.imageUri, let image = UIImage(contentsOfFile: uri) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(10)
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(colors.neonBlue.opacity(0.1))
                                        Image(systemName: "fork.knife")
                                            .foregroundStyle(colors.neonBlue)
                                    }
                                    .frame(width: 50, height: 50)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.foodName ?? "Unknown")
                                        .font(.headline)
                                    Text("\(log.estimatedCalories) kcal • P: \(Int(log.proteinG))g C: \(Int(log.carbsG))g F: \(Int(log.fatG))g")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func addWater(_ amount: Int) {
        if let log = todayLog {
            log.waterML = (log.waterML ?? 0) + amount
        } else {
            let log = DailyLog(date: selectedDateString, waterML: amount)
            modelContext.insert(log)
        }
        try? modelContext.save()
    }
}

// MARK: - Subviews

struct WaterWaveCircle: View {
    var fill: Double
    var color: Color
    @State private var waveOffset = 0.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                color.opacity(0.1)
                
                VStack {
                    Spacer()
                    Wave(offset: waveOffset, amplitude: 5, fill: fill)
                        .fill(color)
                        .frame(height: geo.size.height * CGFloat(fill))
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
}

struct Wave: Shape {
    var offset: Double
    var amplitude: Double
    var fill: Double
    
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = sin(relativeX * .pi * 2 + offset) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Water Intake Sheet
struct WaterIntakeSheet: View {
    @Environment(\.theme) var colors
    @Environment(\.dismiss) var dismiss
    
    let currentML: Int
    let goal: Int
    let onAdd: (Int) -> Void
    
    @State private var customAmount: String = ""
    
    let quickAmounts = [250, 500, 750]
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Status
                    VStack(spacing: 8) {
                        Text("\(currentML) / \(goal) ml")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(colors.neonBlue)
                        
                        ProgressView(value: Double(currentML), total: Double(goal))
                            .tint(colors.neonBlue)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    
                    // Quick Buttons
                    HStack(spacing: 16) {
                        ForEach(quickAmounts, id: \.self) { amount in
                            Button {
                                onAdd(amount)
                                dismiss()
                            } label: {
                                VStack {
                                    Image(systemName: "drop.fill")
                                    Text("\(amount)ml")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Custom Entry
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Amount")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter ml", text: $customAmount)
                                .keyboardType(.numberPad)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            
                            Button {
                                if let amount = Int(customAmount) {
                                    onAdd(amount)
                                    dismiss()
                                }
                            } label: {
                                Text("Add")
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(colors.neonBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

