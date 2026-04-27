import SwiftUI
import Charts

struct WeeklyCaloriesChart: View {
    let data: [DayCalories]
    let colors: DesignSystem.ThemeColors
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Calories", item.calories)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [colors.neonGreen, colors.neonBlue],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(colors.textTertiary.opacity(0.3))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
            }
        } else {
            // Fallback for iOS 16 and earlier
            fallbackChart
        }
    }
    
    private var fallbackChart: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data) { item in
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [colors.neonGreen, colors.neonBlue],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(height: CGFloat(item.calories) / 10)
                    Text(item.day.prefix(3))
                        .font(.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }
}

struct HRVTrendChart: View {
    let data: [HRVDataPoint]
    let colors: DesignSystem.ThemeColors
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Chart(data) { item in
                LineMark(
                    x: .value("Time", item.time),
                    y: .value("HRV", item.hrv)
                )
                .foregroundStyle(colors.neonBlue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Time", item.time),
                    y: .value("HRV", item.hrv)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [colors.neonBlue.opacity(0.3), colors.neonBlue.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYScale(domain: 0...(data.map(\.hrv).max() ?? 100))
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(colors.textTertiary.opacity(0.3))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
            }
        } else {
            PulseLine(dataPoints: data.map(\.hrv), color: colors.neonBlue)
        }
    }
}

struct MacroDonutChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let colors: DesignSystem.ThemeColors
    
    private var total: Double {
        protein + carbs + fat
    }
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Chart {
                SectorMark(
                    angle: .value("Protein", protein),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(colors.protein)
                .annotation(position: .overlay) {
                    if protein / total > 0.2 {
                        Text("\(Int(protein))g")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
                
                SectorMark(
                    angle: .value("Carbs", carbs),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(colors.carbs)
                .annotation(position: .overlay) {
                    if carbs / total > 0.2 {
                        Text("\(Int(carbs))g")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
                
                SectorMark(
                    angle: .value("Fat", fat),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(colors.fat)
                .annotation(position: .overlay) {
                    if fat / total > 0.2 {
                        Text("\(Int(fat))g")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center) {
                HStack(spacing: 16) {
                    LegendItem(color: colors.protein, label: "Protein")
                    LegendItem(color: colors.carbs, label: "Carbs")
                    LegendItem(color: colors.fat, label: "Fat")
                }
            }
        } else {
            // Fallback - show simple bars
            VStack(spacing: 8) {
                macroBar("Protein", protein, colors.protein)
                macroBar("Carbs", carbs, colors.carbs)
                macroBar("Fat", fat, colors.fat)
            }
        }
    }
    
    private func macroBar(_ label: String, _ value: Double, _ color: Color) -> some View {
        let pct = total > 0 ? value / total : 0
        return HStack {
            Text(label).font(.caption).foregroundStyle(colors.textSecondary)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * pct)
            }
            .frame(height: 8)
            Text("\(Int(value))g").font(.caption2).foregroundStyle(color)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
        }
    }
}

// MARK: - Data Models

struct DayCalories: Identifiable {
    let id = UUID()
    let day: String
    let calories: Int
}

struct HRVDataPoint: Identifiable {
    let id = UUID()
    let time: String
    let hrv: Double
}