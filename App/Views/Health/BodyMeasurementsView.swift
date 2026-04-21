import SwiftUI
import SwiftData

// MARK: - Body Measurements

@Model
final class BodyMeasurement {
    @Attribute(.unique) var id: UUID
    var date: String // YYYY-MM-DD
    var weightKg: Double
    var waistCm: Double
    var heightCm: Double
    var notes: String
    
    init(date: String, weightKg: Double = 0, waistCm: Double = 0, heightCm: Double = 0, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.waistCm = waistCm
        self.heightCm = heightCm
        self.notes = notes
    }
    
    var bmi: Double {
        guard heightCm > 0, weightKg > 0 else { return 0 }
        let h = heightCm / 100
        return weightKg / (h * h)
    }
}

// MARK: - Body Measurements View

struct BodyMeasurementsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    
    @State private var showingAdd = false
    @State private var selectedMetric = 0 // 0=weight, 1=waist, 2=BMI
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Current stats
                if let latest = measurements.first {
                    currentStatsCard(measurement: latest)
                }
                
                // Trend chart
                trendCard
                
                // Add button
                Button {
                    showingAdd = true
                } label: {
                    Label("Log Measurement", systemImage: "plus.circle.fill")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonGreen.gradient))
                }
                .buttonStyle(.scaleButton)
                .padding(.horizontal)
                
                // History
                if !measurements.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("History")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(colors.textPrimary)
                        
                        ForEach(measurements.prefix(10)) { m in
                            measurementRow(m)
                        }
                    }
                    .themedCard()
                    .padding(.horizontal)
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.top)
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("Body Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(colors.neonGreen)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddMeasurementView(colors: colors) { weight, waist, height, notes in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let m = BodyMeasurement(date: formatter.string(from: Date()), weightKg: weight, waistCm: waist, heightCm: height, notes: notes)
                modelContext.insert(m)
                try? modelContext.save()
                Haptic.notification(.success)
            }
        }
    }
    
    private func currentStatsCard(measurement: BodyMeasurement) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Current Stats")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                statTile(icon: "scalemass.fill", label: "Weight", value: measurement.weightKg > 0 ? String(format: "%.1f kg", measurement.weightKg) : "—", color: colors.neonBlue)
                statTile(icon: "ruler", label: "Waist", value: measurement.waistCm > 0 ? String(format: "%.0f cm", measurement.waistCm) : "—", color: colors.neonOrange)
                statTile(icon: "heart.fill", label: "BMI", value: measurement.bmi > 0 ? String(format: "%.1f", measurement.bmi) : "—", color: bmiColor(measurement.bmi))
            }
        }
        .themedCard()
        .padding(.horizontal)
    }
    
    private func statTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(colors.textPrimary)
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).fill(colors.backgroundElevated))
    }
    
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Metric picker
            Picker("Metric", selection: $selectedMetric) {
                Text("Weight").tag(0)
                Text("Waist").tag(1)
                Text("BMI").tag(2)
            }
            .pickerStyle(.segmented)
            
            // Mini trend line
            if measurements.count >= 2 {
                let values = measurements.prefix(30).reversed().map { m -> Double in
                    switch selectedMetric {
                    case 0: return m.weightKg
                    case 1: return m.waistCm
                    default: return m.bmi
                    }
                }.filter { $0 > 0 }
                
                if values.count >= 2 {
                    MiniTrendLine(data: values, color: selectedMetric == 0 ? colors.neonBlue : selectedMetric == 1 ? colors.neonOrange : colors.neonGreen)
                        .frame(height: 80)
                    
                    // Change indicator
                    let change = values.last! - values.first!
                    HStack {
                        Text("Change:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                        Text(String(format: "%+.1f", change))
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(change < 0 ? colors.neonGreen : change > 0 ? colors.neonRed : colors.textSecondary)
                        Text(selectedMetric == 0 ? "kg" : selectedMetric == 1 ? "cm" : "")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(colors.textTertiary)
                        Spacer()
                        Text("\(values.count) entries")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(colors.textTertiary)
                    }
                } else {
                    Text("Need at least 2 entries for trend")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
            } else {
                Text("Log measurements to see trends")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .themedCard()
        .padding(.horizontal)
    }
    
    private func measurementRow(_ m: BodyMeasurement) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(m.date)
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(colors.textPrimary)
                if !m.notes.isEmpty {
                    Text(m.notes)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                }
            }
            Spacer()
            if m.weightKg > 0 {
                Text(String(format: "%.1f kg", m.weightKg))
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(colors.neonBlue)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
    }
    
    private func bmiColor(_ bmi: Double) -> Color {
        if bmi <= 0 { return colors.textTertiary }
        if bmi < 18.5 { return colors.neonBlue }
        if bmi < 25 { return colors.neonGreen }
        if bmi < 30 { return colors.neonYellow }
        return colors.neonRed
    }
}

// MARK: - Mini Trend Line

struct MiniTrendLine: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minVal = data.min() ?? 0
            let maxVal = data.max() ?? 1
            let range = maxVal - minVal
            
            ZStack {
                // Line
                Path { path in
                    for (i, val) in data.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(max(data.count - 1, 1))
                        let normalized = range > 0 ? (val - minVal) / range : 0.5
                        let y = h - (CGFloat(normalized) * h * 0.8 + h * 0.1)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // Gradient fill
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    for (i, val) in data.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(max(data.count - 1, 1))
                        let normalized = range > 0 ? (val - minVal) / range : 0.5
                        let y = h - (CGFloat(normalized) * h * 0.8 + h * 0.1)
                        if i == 0 { path.addLine(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                
                // Dots
                ForEach(Array(data.enumerated()), id: \.offset) { i, val in
                    let x = w * CGFloat(i) / CGFloat(max(data.count - 1, 1))
                    let normalized = range > 0 ? (val - minVal) / range : 0.5
                    let y = h - (CGFloat(normalized) * h * 0.8 + h * 0.1)
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Add Measurement Sheet

struct AddMeasurementView: View {
    @Environment(\.dismiss) var dismiss
    let colors: DesignSystem.ThemeColors
    let onSave: (Double, Double, Double, String) -> Void
    
    @State private var weight = ""
    @State private var waist = ""
    @State private var height = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                fieldInput("Weight (kg)", text: $weight, icon: "scalemass", keyboard: .decimalPad)
                fieldInput("Waist (cm)", text: $waist, icon: "ruler", keyboard: .decimalPad)
                fieldInput("Height (cm)", text: $height, icon: "ruler", keyboard: .decimalPad)
                fieldInput("Notes (optional)", text: $notes, icon: "text.alignleft")
                
                Spacer()
                
                Button {
                    onSave(Double(weight) ?? 0, Double(waist) ?? 0, Double(height) ?? 0, notes)
                    dismiss()
                } label: {
                    Text("Save")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonGreen.gradient))
                }
                .buttonStyle(.scaleButton)
            }
            .padding()
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Log Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(colors.textSecondary)
                }
            }
        }
    }
    
    private func fieldInput(_ label: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon).font(.caption).foregroundStyle(colors.textTertiary).frame(width: 16)
            TextField(label, text: text)
                .keyboardType(keyboard)
                .foregroundStyle(colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
    }
}
