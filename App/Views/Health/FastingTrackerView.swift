import SwiftUI

// MARK: - Fasting Tracker

struct FastingTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @AppStorage("fasting_start") private var fastingStartRaw: Double = 0
    @AppStorage("fasting_goal_hours") private var fastingGoalHours: Int = 16
    @AppStorage("fasting_active") private var isFasting = false
    
    @State private var currentTime = Date()
    @State private var showingGoalPicker = false
    @State private var animateRing = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var fastingStart: Date? {
        fastingStartRaw > 0 ? Date(timeIntervalSince1970: fastingStartRaw) : nil
    }
    
    private var elapsedSeconds: Double {
        guard let start = fastingStart, isFasting else { return 0 }
        return currentTime.timeIntervalSince(start)
    }
    
    private var elapsedHours: Double { elapsedSeconds / 3600.0 }
    private var goalSeconds: Double { Double(fastingGoalHours) * 3600.0 }
    private var progress: Double { min(elapsedSeconds / goalSeconds, 1.0) }
    
    private var remainingSeconds: Double { max(goalSeconds - elapsedSeconds, 0) }
    private var remainingHours: Int { Int(remainingSeconds) / 3600 }
    private var remainingMinutes: Int { (Int(remainingSeconds) % 3600) / 60 }
    private var remainingSecondsPart: Int { Int(remainingSeconds) % 60 }
    
    private var isComplete: Bool { elapsedSeconds >= goalSeconds }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Title
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "timer")
                        .font(.system(size: 40))
                        .foregroundStyle(isComplete ? colors.neonGreen : colors.neonPurple)
                        .neonGlow(isComplete ? colors.neonGreen : colors.neonPurple, intensity: 0.5)
                    
                    Text("Fasting Tracker")
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(colors.textPrimary)
                    
                    Text("\(fastingGoalHours)h fasting / \(24 - fastingGoalHours)h eating")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Main Timer Ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(colors.cardBorder, lineWidth: 16)
                        .frame(width: 240, height: 240)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: animateRing ? progress : 0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: isComplete
                                    ? [colors.neonGreen, colors.neonGreen.opacity(0.6)]
                                    : [colors.neonPurple, colors.neonBlue]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
                    
                    // Glow dot at tip
                    if progress > 0.02 && !isComplete {
                        Circle()
                            .fill(colors.neonPurple)
                            .frame(width: 14, height: 14)
                            .shadow(color: colors.neonPurple, radius: 8)
                            .offset(y: -120)
                            .rotationEffect(.degrees(360 * progress))
                    }
                    
                    // Center content
                    VStack(spacing: 4) {
                        if isFasting {
                            if isComplete {
                                Text("Complete!")
                                    .font(DesignSystem.Typography.title3)
                                    .foregroundStyle(colors.neonGreen)
                                Text("\(formatHoursMinutes(elapsedHours))")
                                    .font(DesignSystem.Typography.statLarge)
                                    .foregroundStyle(colors.neonGreen)
                                    .monospacedDigit()
                            } else {
                                Text("Remaining")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(colors.textSecondary)
                                Text(String(format: "%02d:%02d:%02d", remainingHours, remainingMinutes, remainingSecondsPart))
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(colors.textPrimary)
                                    .onReceive(timer) { _ in
                                        currentTime = Date()
                                    }
                            }
                        } else {
                            Text("Not Fasting")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(colors.textSecondary)
                            Text("Tap Start to begin")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(colors.textTertiary)
                        }
                    }
                }
                
                // Stats row
                if isFasting {
                    HStack(spacing: DesignSystem.Spacing.xl) {
                        statBlock(label: "Started", value: formatTime(fastingStart), color: colors.neonPurple)
                        statBlock(label: "Elapsed", value: formatHoursMinutes(elapsedHours), color: colors.neonBlue)
                        statBlock(label: "Goal", value: "\(fastingGoalHours)h", color: colors.neonGreen)
                    }
                    .padding(.horizontal)
                }
                
                // Control buttons
                HStack(spacing: DesignSystem.Spacing.md) {
                    if isFasting {
                        // Stop button
                        Button {
                            Haptic.notification(.warning)
                            withAnimation { stopFasting() }
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonRed.gradient))
                        }
                        .buttonStyle(.scaleButton)
                    } else {
                        // Start button
                        Button {
                            Haptic.notification(.success)
                            withAnimation { startFasting() }
                        } label: {
                            Label("Start Fasting", systemImage: "play.fill")
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonPurple.gradient))
                        }
                        .buttonStyle(.scaleButton)
                    }
                }
                .padding(.horizontal)
                
                // Goal picker
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Fasting Goal")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.textPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach([12, 14, 16, 18, 20], id: \.self) { hours in
                            Button {
                                Haptic.selection()
                                fastingGoalHours = hours
                            } label: {
                                VStack(spacing: 2) {
                                    Text("\(hours)h")
                                        .font(DesignSystem.Typography.bodyBold)
                                        .foregroundStyle(fastingGoalHours == hours ? .white : colors.textPrimary)
                                    Text("\(24 - hours)h eat")
                                        .font(DesignSystem.Typography.caption2)
                                        .foregroundStyle(fastingGoalHours == hours ? .white.opacity(0.7) : colors.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(fastingGoalHours == hours ? colors.neonPurple : colors.backgroundElevated)
                                )
                            }
                            .buttonStyle(.scaleButton)
                        }
                    }
                }
                .themedCard()
                .padding(.horizontal)
                
                // Tips
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Label("Fasting Tips", systemImage: "lightbulb.fill")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.neonYellow)
                    
                    tipRow("Drink water, black coffee, or plain tea during fasting")
                    tipRow("Ease into it — start with 12h and work up to 16h+")
                    tipRow("Break your fast with light foods (fruit, soup)")
                    tipRow("Avoid fasting if pregnant, diabetic, or on medication")
                }
                .themedCard()
                .padding(.horizontal)
                
                Spacer().frame(height: 100)
            }
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("Fasting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(colors.neonPurple)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0).delay(0.2)) { animateRing = true }
            currentTime = Date()
        }
    }
    
    // MARK: - Actions
    
    private func startFasting() {
        fastingStartRaw = Date().timeIntervalSince1970
        isFasting = true
    }
    
    private func stopFasting() {
        isFasting = false
        fastingStartRaw = 0
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
    
    private func formatHoursMinutes(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
    
    private func statBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(colors.textTertiary)
            Text(value)
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(color)
        }
    }
    
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundStyle(colors.neonYellow)
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
        }
    }
}
