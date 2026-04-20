import SwiftUI

struct WeeklyCalendarView: View {
    @Environment(\.theme) var colors
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    
    private var dates: [Date] {
        // Show 5 days before today, today, and tomorrow
        let today = calendar.startOfDay(for: Date())
        return (-5...1).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 8) {
                    ForEach(dates, id: \.self) { date in
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text(dayOfWeek(date))
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundStyle(isSelected ? .white : colors.textSecondary)
                                
                                Text(dayNumber(date))
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.heavy)
                                    .foregroundStyle(isSelected ? .white : colors.textPrimary)
                                
                                if isToday && !isSelected {
                                    Circle()
                                        .fill(colors.neonBlue)
                                        .frame(width: 5, height: 5)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .frame(width: 48, height: 76)
                            .background(
                                Group {
                                    if #available(iOS 26, *) {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.clear)
                                            .glassEffect(isSelected ? .regular.tint(colors.neonBlue).interactive() : .regular.interactive(), in: .rect(cornerRadius: 16))
                                    } else {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(isSelected ? AnyShapeStyle(colors.neonBlue.gradient) : AnyShapeStyle(.ultraThinMaterial))
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(isSelected ? Color.clear : colors.cardBorder.opacity(0.15), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .id(date)
                    }
                }
                .padding(.horizontal, 16)
                .onAppear {
                    proxy.scrollTo(calendar.startOfDay(for: Date()), anchor: .center)
                }
            }
        }
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
