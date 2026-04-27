import SwiftUI
import SwiftData
import EventKit

struct ProgressTabView: View {
    @Environment(\.theme) var colors
    @Query(sort: \DailyLog.date) private var allLogs: [DailyLog]
    
    @State private var selectedMonth = Date()
    @State private var selectedDate = Date()
    @State private var nativeEvents: [EKEvent] = []
    
    @State private var showingAddOptions = false
    @State private var showingEventEditor = false
    @State private var newEventDraft: EKEvent? = nil
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                // Animated gradient background
                LinearGradient(
                    colors: [colors.neonBlue.opacity(0.05), colors.neonPurple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Month Navigation with glass effect
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundStyle(colors.neonBlue)
                                    .padding(12)
                                    .background {
                                        if #available(iOS 26, *) {
                                            Circle()
                                                .glassEffect(.regular.interactive())
                                        } else {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                            }
                            .buttonStyle(.scaleButton)
                            
                            Spacer()
                            
                            Text(monthYearString)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.heavy)
                                .foregroundStyle(colors.textPrimary)
                                .scaleEffect(selectedMonth == Date() ? 1.0 : 0.95)
                                .animation(.spring(response: 0.3), value: selectedMonth)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundStyle(colors.neonBlue)
                                    .padding(12)
                                    .background {
                                        if #available(iOS 26, *) {
                                            Circle()
                                                .glassEffect(.regular.interactive())
                                        } else {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                            }
                            .buttonStyle(.scaleButton)
                        }
                        .padding(.horizontal, 4)
                        
                        // Calendar Grid with enhanced styling
                        GlassCard {
                            calendarGrid
                        }
                        
                        // Detail Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(dateFormatter.string(from: selectedDate))
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.top, 8)
                            
                            // App Log
                            if let log = logForSelectedDate {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(log.goalCompleted == 1 ? .green : .red)
                                        .frame(width: 12, height: 12)
                                    VStack(alignment: .leading) {
                                        Text("Daily Goal")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(log.goalCompleted == 1 ? "Completed" : "Missed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.5))
                                .cornerRadius(12)
                            } else {
                                Text("No app logs for this day.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Native Events
                            if PermissionsService.shared.hasCalendarFullAccess {
                                if !nativeEvents.isEmpty {
                                    Text("Calendar Events")
                                        .font(.headline)
                                        .padding(.top, 8)
                                    
                                    ForEach(nativeEvents, id: \.eventIdentifier) { event in
                                        NativeCalendarEventView(event: event)
                                    }
                                }
                            } else {
                                Button("Sync Apple Calendar") {
                                    Task {
                                        if try await PermissionsService.shared.requestCalendarFullAccess() {
                                            fetchEvents()
                                        }
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                            }
                        }
                        
                        // Monthly Score with enhanced styling
                        GlassCard(cornerRadius: 24) {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title2)
                                        .foregroundStyle(colors.neonBlue)
                                    Text("Monthly Consistency")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                
                                let score = monthlyScore
                                Text(String(format: "%.1f", score))
                                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                                    .foregroundStyle(score >= 7 ? colors.neonGreen : score >= 4 ? colors.neonYellow : colors.neonRed)
                                    .contentTransition(.numericText())
                                    .symbolEffect(.bounce, isActive: score >= 7)
                                
                                Text("out of 10")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 20) {
                                    HStack(spacing: 6) {
                                        Circle().fill(colors.neonGreen).frame(width: 10, height: 10)
                                        Text("\(greenDays) days completed")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(colors.textSecondary)
                                    }
                                    HStack(spacing: 6) {
                                        Circle().fill(colors.neonRed).frame(width: 10, height: 10)
                                        Text("\(redDays) days missed")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(colors.textSecondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddOptions = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                selectedDate = calendar.startOfDay(for: Date())
                fetchEvents()
            }
            .onChange(of: selectedDate) { _, _ in
                fetchEvents()
            }
            .sheet(isPresented: $showingAddOptions) {
                AddIntegrationActionSheet(
                    onAddAppointment: { openEventEditor() },
                    onAddReminder: { createQuickReminder() }
                )
            }
            .sheet(isPresented: $showingEventEditor) {
                if let event = newEventDraft {
                    CalendarEventEditor(event: event, eventStore: PermissionsService.shared.eventStore)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        let daysInMonth = datesInMonth
        let firstWeekday = calendar.component(.weekday, from: daysInMonth.first ?? Date())
        let leadingSpaces = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        return VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            let allCells = Array(repeating: Date?.none, count: leadingSpaces) + daysInMonth.map { Optional($0) }
            let rows = stride(from: 0, to: allCells.count, by: 7).map { Array(allCells[$0..<min($0 + 7, allCells.count)]) }
            
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { col in
                        if col < row.count, let date = row[col] {
                            dayCell(for: date)
                        } else {
                            Text("")
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                    }
                }
            }
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        let day = calendar.component(.day, from: date)
        
        let goalLog = allLogs.first { $0.date == dateStr && $0.goalCompleted != nil }
        let goalCompleted = goalLog?.goalCompleted
        let isPast = date < calendar.startOfDay(for: Date())
        
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
            }
        }) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [colors.neonBlue, colors.neonPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: colors.neonBlue.opacity(0.4), radius: 8)
                } else if isToday {
                    Circle()
                        .stroke(colors.neonBlue, lineWidth: 2)
                        .shadow(color: colors.neonBlue.opacity(0.3), radius: 4)
                }
                
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundStyle(isSelected ? .white : (isToday ? colors.neonBlue : colors.textPrimary))
                    
                    if goalCompleted != nil {
                        Circle()
                            .fill(cellColor(goalCompleted: goalCompleted, isPast: isPast, isToday: false))
                            .frame(width: 4, height: 4)
                    } else if !isPast && !isToday {
                        Circle().fill(Color.clear).frame(width: 4, height: 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .buttonStyle(.plain)
    }
    
    private func cellColor(goalCompleted: Int?, isPast: Bool, isToday: Bool) -> Color {
        if isToday { return .blue }
        guard isPast else { return .clear }
        
        switch goalCompleted {
        case 1: return .green.opacity(0.3)
        case 0: return .red.opacity(0.3)
        default: return .gray.opacity(0.1)
        }
    }
    
    // MARK: - Computed
    
    private var datesInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var greenDays: Int {
        goalLogs.filter { $0.goalCompleted == 1 }.count
    }
    
    private var redDays: Int {
        goalLogs.filter { $0.goalCompleted == 0 }.count
    }
    
    private var goalLogs: [DailyLog] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthStr = formatter.string(from: selectedMonth)
        return allLogs.filter { $0.date.hasPrefix(monthStr) && $0.goalCompleted != nil }
    }
    
    private var monthlyScore: Double {
        let daysElapsed = min(calendar.component(.day, from: Date()), datesInMonth.count)
        guard daysElapsed > 0 else { return 0 }
        return (Double(greenDays) / Double(daysElapsed)) * 10.0
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private var logForSelectedDate: DailyLog? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)
        return allLogs.first { $0.date == dateStr && $0.goalCompleted != nil }
    }
    
    // MARK: - Integration Flow
    
    private func fetchEvents() {
        guard PermissionsService.shared.hasCalendarFullAccess else { return }
        do {
            let allUpcoming = try CalendarService.shared.fetchUpcomingEvents(daysAhead: 30) // fetch a chunk
            // filter dynamically for selected date
            nativeEvents = allUpcoming.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
        } catch {
            print("Could not fetch events: \(error)")
        }
    }
    
    private func openEventEditor() {
        // Pre-fill a draft appointment on the selected date
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? Date()
        let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? Date()
        
        newEventDraft = CalendarService.shared.draftEvent(
            title: "Health Appointment",
            startDate: start,
            endDate: end,
            notes: "Created via HealthApp"
        )
        
        showingEventEditor = true
    }
    
    private func createQuickReminder() {
        Task {
            do {
                if try await PermissionsService.shared.requestRemindersAccess() {
                    let due = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: selectedDate)
                    _ = try ReminderService.shared.createReminder(
                        title: "Log Health Metrics",
                        notes: "Reminder from HealthApp",
                        dueDate: due
                    )
                    // Haptic feedback to show success on a real device
                }
            } catch {
                print("Could not create reminder: \(error)")
            }
        }
    }
}
