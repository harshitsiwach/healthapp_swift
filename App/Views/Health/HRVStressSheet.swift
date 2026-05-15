import SwiftUI

// MARK: - HRV & Stress Logging Sheet

struct HRVStressSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    
    let currentHRV: Double
    let currentStress: Int
    let onSave: (Double, Int) -> Void
    
    @State private var hrvValue: Double
    @State private var stressValue: Int
    @State private var animateIn = false
    
    init(currentHRV: Double, currentStress: Int, onSave: @escaping (Double, Int) -> Void) {
        self.currentHRV = currentHRV
        self.currentStress = currentStress
        self.onSave = onSave
        self._hrvValue = State(initialValue: currentHRV > 0 ? currentHRV : 50)
        self._stressValue = State(initialValue: currentStress > 0 ? currentStress : 5)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    headerSection
                    hrvSection
                    stressSection
                    correlationInsight
                    saveButton
                }
                .padding()
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Heart & Stress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.neonRed)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6).delay(0.1)) { animateIn = true }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(hrvColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateIn ? 1.2 : 0.8)
                    .opacity(animateIn ? 0 : 1)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: animateIn)
                
                // Main heart
                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(hrvColor)
                    .neonGlow(hrvColor, intensity: 0.5)
                    .heartbeat(active: true)
            }
            
            Text("Heart Rate Variability & Stress")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(colors.textPrimary)
            
            Text("Track your autonomic nervous system health")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
        }
        .padding(.top, DesignSystem.Spacing.md)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - HRV Section
    
    private var hrvSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Heart Rate Variability")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(colors.textPrimary)
                Spacer()
                Text("\(Int(hrvValue)) ms")
                    .font(DesignSystem.Typography.statMedium)
                    .foregroundStyle(hrvColor)
                    .contentTransition(.numericText())
            }
            
            // HRV quality indicator
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<5) { i in
                    let threshold = Double(i + 1) * 20
                    RoundedRectangle(cornerRadius: 4)
                        .fill(hrvValue >= threshold ? hrvColor : hrvColor.opacity(0.15))
                        .frame(height: 8)
                        .animation(.spring(response: 0.4).delay(Double(i) * 0.05), value: hrvValue)
                }
            }
            
            Text(hrvQualityText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(hrvColor)
            
            // Slider
            VStack(spacing: 4) {
                Slider(value: $hrvValue, in: 10...150, step: 1)
                    .tint(hrvColor)
                
                HStack {
                    Text("Low (10ms)")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                    Spacer()
                    Text("High (150ms)")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textTertiary)
                }
            }
            
            // HRV explanation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(colors.textTertiary)
                Text("HRV measures the variation in time between heartbeats. Higher values generally indicate better stress resilience and recovery.")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(colors.backgroundCard)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(colors.cardBorder))
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - Stress Section
    
    private var stressSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Stress Level")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(colors.textPrimary)
                Spacer()
                Text("\(stressValue)/10")
                    .font(DesignSystem.Typography.statMedium)
                    .foregroundStyle(stressColor)
                    .contentTransition(.numericText())
            }
            
            // Stress emoji indicator
            HStack(spacing: DesignSystem.Spacing.md) {
                ForEach(1..<11) { level in
                    Button {
                        Haptic.selection()
                        withAnimation(.spring(response: 0.3)) {
                            stressValue = level
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(stressEmoji(for: level))
                                .font(.system(size: stressValue == level ? 28 : 20))
                                .scaleEffect(stressValue == level ? 1.1 : 1.0)
                            
                            Text("\(level)")
                                .font(.system(size: 10, weight: stressValue == level ? .bold : .regular, design: .rounded))
                                .foregroundStyle(stressValue == level ? stressColor : colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.spring(response: 0.4), value: stressValue)
            
            Text(stressQualityText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(stressColor)
            
            // Stress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [colors.neonGreen, colors.neonYellow, colors.neonOrange, colors.neonRed],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .opacity(0.2)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stressColor)
                        .frame(width: geo.size.width * Double(stressValue) / 10.0)
                        .animation(.spring(response: 0.5), value: stressValue)
                }
            }
            .frame(height: 8)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(colors.backgroundCard)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(colors.cardBorder))
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - Correlation Insight
    
    private var correlationInsight: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Label("Insight", systemImage: "lightbulb.fill")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.neonYellow)
            
            Text(insightText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(colors.neonYellow.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(colors.neonYellow.opacity(0.2)))
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            onSave(hrvValue, stressValue)
            Haptic.notification(.success)
            dismiss()
        } label: {
            Text("Save Readings")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(hrvColor.gradient)
                )
        }
        .buttonStyle(.scaleButton)
        .padding(.bottom, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Helpers
    
    private var hrvColor: Color {
        if hrvValue >= 80 { return colors.neonGreen }
        if hrvValue >= 50 { return colors.neonYellow }
        if hrvValue >= 30 { return colors.neonOrange }
        return colors.neonRed
    }
    
    private var hrvQualityText: String {
        if hrvValue >= 80 { return "Excellent — Strong recovery capacity" }
        if hrvValue >= 60 { return "Good — Healthy autonomic function" }
        if hrvValue >= 40 { return "Fair — Consider more rest" }
        if hrvValue >= 25 { return "Low — Stress is affecting your body" }
        return "Very Low — Prioritize recovery"
    }
    
    private var stressColor: Color {
        if stressValue <= 3 { return colors.neonGreen }
        if stressValue <= 5 { return colors.neonYellow }
        if stressValue <= 7 { return colors.neonOrange }
        return colors.neonRed
    }
    
    private var stressQualityText: String {
        if stressValue <= 2 { return "Very relaxed — Enjoy the calm" }
        if stressValue <= 4 { return "Mild stress — Normal daily level" }
        if stressValue <= 6 { return "Moderate — Consider a break" }
        if stressValue <= 8 { return "High — Try breathing exercises" }
        return "Very high — Seek support if needed"
    }
    
    private var insightText: String {
        if hrvValue >= 60 && stressValue <= 4 {
            return "Your body is well-recovered. Great time for intense activity or creative work."
        } else if hrvValue < 40 && stressValue > 6 {
            return "Low HRV + high stress = your body needs rest. Try deep breathing: 4s inhale, 7s hold, 8s exhale."
        } else if hrvValue < 50 {
            return "Your HRV suggests accumulated fatigue. Prioritize sleep and light movement today."
        } else if stressValue > 6 {
            return "High stress detected. A 10-min walk or meditation session can help lower cortisol."
        }
        return "Your readings look balanced. Keep monitoring to spot patterns over time."
    }
    
    private func stressEmoji(for level: Int) -> String {
        switch level {
        case 1...2: return "😌"
        case 3...4: return "🙂"
        case 5...6: return "😐"
        case 7...8: return "😟"
        case 9...10: return "😰"
        default: return "😐"
        }
    }
}
