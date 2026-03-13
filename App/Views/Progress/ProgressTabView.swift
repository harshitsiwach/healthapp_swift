import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Query(sort: \DailyLog.date) private var allLogs: [DailyLog]
    
    @State private var selectedMonth = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Month Navigation
                        HStack {
                            Button {
                                withAnimation {
                                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            
                            Spacer()
                            
                            Text(monthYearString)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.heavy)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Calendar Grid
                        GlassCard(material: .regularMaterial) {
                            calendarGrid
                        }
                        
                        // Monthly Score
                        GlassCard(material: .regularMaterial, cornerRadius: 24) {
                            VStack(spacing: 12) {
                                Text("Monthly Consistency")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                
                                let score = monthlyScore
                                Text(String(format: "%.1f", score))
                                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                                    .foregroundStyle(score >= 7 ? .green : score >= 4 ? .orange : .red)
                                
                                Text("out of 10")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 20) {
                                    HStack(spacing: 6) {
                                        Circle().fill(.green).frame(width: 10, height: 10)
                                        Text("\(greenDays) days completed")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    HStack(spacing: 6) {
                                        Circle().fill(.red).frame(width: 10, height: 10)
                                        Text("\(redDays) days missed")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
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
        
        return Text("\(day)")
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(isToday ? .heavy : .medium)
            .foregroundStyle(isToday ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                Circle()
                    .fill(cellColor(goalCompleted: goalCompleted, isPast: isPast, isToday: isToday))
            )
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
}
