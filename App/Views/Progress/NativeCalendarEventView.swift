import SwiftUI
import EventKit

/// Renders a native Apple Calendar event in a SwiftUI list/card style
struct NativeCalendarEventView: View {
    @Environment(\.theme) var colors
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Calendar Color Strip
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 4)
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(colors.textPrimary)
                
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if event.isAllDay {
                    Text("All day")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(colors.textPrimary)
                } else {
                    Text(timeString(from: event.startDate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(timeString(from: event.endDate))
                        .font(.caption2)
                        .foregroundColor(colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            if #available(iOS 26, *) {
                GlassEffectContainer { }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.backgroundCard)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colors.cardBorder.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
