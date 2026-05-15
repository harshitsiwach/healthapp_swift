import SwiftUI

struct DailyHealthSummaryCard: View {
    @Environment(\.theme) var colors
    let summary: DailyHealthSummary
    
    var body: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "apple.medicate")
                        .foregroundStyle(colors.protein)
                    Text("HealthKit Sync")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    Spacer()
                    Text("Today")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(colors.textSecondary)
                }
                
                HStack(spacing: 20) {
                    healthMetric(icon: "figure.walk", value: "\(Int(summary.steps))", unit: "steps", color: colors.neonGreen)
                    
                    if let sleep = summary.lastNightSleepHours {
                        healthMetric(icon: "bed.double.fill", value: String(format: "%.1f", sleep), unit: "hrs", color: colors.neonPurple)
                    }
                    
                    if let hr = summary.latestHeartRate {
                        healthMetric(icon: "heart.fill", value: "\(Int(hr))", unit: "bpm", color: colors.neonRed)
                    }
                }
            }
        }
    }
    
    private func healthMetric(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.heavy)
                Text(unit)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(colors.textSecondary)
            }
        }
    }
}
