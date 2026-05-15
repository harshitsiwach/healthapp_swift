import SwiftUI
import SwiftData

struct WaterReminderView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    
    @AppStorage("water_reminder_enabled") private var isEnabled = false
    @AppStorage("water_reminder_interval") private var intervalMinutes = 120
    @AppStorage("water_reminder_start") private var startHour = 8
    @AppStorage("water_reminder_end") private var endHour = 22
    
    let intervals = [60, 90, 120, 150, 180]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(colors.neonBlue)
                        .neonGlow(colors.neonBlue, intensity: 0.5)
                    
                    Text("Water Reminders")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(colors.textPrimary)
                    
                    Text("Stay hydrated with smart notifications")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Toggle
                Toggle(isOn: $isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Reminders")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(colors.textPrimary)
                        Text(isEnabled ? "You'll be reminded every \(intervalMinutes / 60)h \(intervalMinutes % 60)m" : "Notifications are off")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .tint(colors.neonBlue)
                .themedCard()
                .padding(.horizontal)
                .onChange(of: isEnabled) { _, newValue in
                    if newValue {
                        scheduleNotifications()
                    } else {
                        cancelNotifications()
                    }
                }
                
                if isEnabled {
                    // Interval picker
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Remind every")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(colors.textPrimary)
                        
                        HStack(spacing: 10) {
                            ForEach(intervals, id: \.self) { mins in
                                Button {
                                    Haptic.selection()
                                    intervalMinutes = mins
                                    scheduleNotifications()
                                } label: {
                                    Text(mins >= 60 ? "\(mins/60)h\(mins%60 > 0 ? " \(mins%60)m" : "")" : "\(mins)m")
                                        .font(DesignSystem.Typography.captionBold)
                                        .foregroundStyle(intervalMinutes == mins ? .white : colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                .fill(intervalMinutes == mins ? colors.neonBlue : colors.backgroundElevated)
                                        )
                                }
                                .buttonStyle(.scaleButton)
                            }
                        }
                    }
                    .themedCard()
                    .padding(.horizontal)
                    
                    // Active hours
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Active Hours")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(colors.textPrimary)
                        
                        HStack {
                            VStack {
                                Text("From")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(colors.textSecondary)
                                Picker("Start", selection: $startHour) {
                                    ForEach(5..<13) { Text("\($0):00").tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(colors.neonBlue)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .foregroundStyle(colors.textTertiary)
                            
                            Spacer()
                            
                            VStack {
                                Text("To")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(colors.textSecondary)
                                Picker("End", selection: $endHour) {
                                    ForEach(18..<24) { Text("\($0):00").tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(colors.neonBlue)
                            }
                        }
                    }
                    .themedCard()
                    .padding(.horizontal)
                    
                    // Preview
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Label("Schedule Preview", systemImage: "bell.fill")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(colors.neonBlue)
                        
                        let count = (endHour - startHour) * 60 / intervalMinutes
                        Text("You'll receive ~\(count) reminders per day")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<min(count, 6), id: \.self) { i in
                                let hour = startHour + (i * intervalMinutes / 60)
                                Text("\(hour):00")
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundStyle(colors.neonBlue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(colors.neonBlue.opacity(0.12)))
                            }
                            if count > 6 {
                                Text("+\(count - 6) more")
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundStyle(colors.textTertiary)
                            }
                        }
                    }
                    .themedCard()
                    .padding(.horizontal)
                }
                
                Spacer().frame(height: 100)
            }
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(colors.neonBlue)
            }
        }
    }
    
    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Hydrate! 💧"
            content.body = ["Drink a glass of water", "Stay hydrated!", "Water break time!", "Your body needs water", "Hydration check!"].randomElement()!
            content.sound = .default
            
            for hour in stride(from: startHour, to: endHour, by: intervalMinutes / 60) {
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = 0
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "water_\(hour)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Medication Reminders

struct MedicationRemindersView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @Query private var passports: [MedicalPassport]
    
    @AppStorage("med_reminders_enabled") private var isEnabled = false
    @State private var customMedications: [MedReminder] = []
    @State private var showingAdd = false
    
    var medications: [Medication] {
        passports.first?.medications ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "pill.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(colors.neonPurple)
                        .neonGlow(colors.neonPurple, intensity: 0.5)
                    
                    Text("Medication Reminders")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(colors.textPrimary)
                    
                    Text("Never miss a dose")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Toggle
                Toggle(isOn: $isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Reminders")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(colors.textPrimary)
                        Text(isEnabled ? "Reminders active" : "Notifications off")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .tint(colors.neonPurple)
                .themedCard()
                .padding(.horizontal)
                
                // From Medical Passport
                if !medications.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Label("From Medical Passport", systemImage: "heart.text.square.fill")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(colors.neonPurple)
                        
                        ForEach(medications) { med in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med.name)
                                        .font(DesignSystem.Typography.bodyBold)
                                        .foregroundStyle(colors.textPrimary)
                                    Text("\(med.dosage) · \(med.frequency)")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(colors.textSecondary)
                                }
                                Spacer()
                                if isEnabled {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundStyle(colors.neonPurple)
                                }
                            }
                            .padding(DesignSystem.Spacing.sm)
                            .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
                        }
                    }
                    .themedCard()
                    .padding(.horizontal)
                }
                
                // Add custom reminder
                Button {
                    showingAdd = true
                } label: {
                    Label("Add Custom Reminder", systemImage: "plus.circle.fill")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonPurple.gradient))
                }
                .buttonStyle(.scaleButton)
                .padding(.horizontal)
                
                // Tips
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Label("Tips", systemImage: "lightbulb.fill")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.neonYellow)
                    tipRow("Add medications in Medical Passport first")
                    tipRow("Reminders sync with your medication schedule")
                    tipRow("Set specific times for better compliance")
                }
                .themedCard()
                .padding(.horizontal)
                
                Spacer().frame(height: 100)
            }
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(colors.neonPurple)
            }
        }
    }
    
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundStyle(colors.neonYellow)
            Text(text).font(DesignSystem.Typography.caption).foregroundStyle(colors.textSecondary)
        }
    }
}

struct MedReminder: Identifiable, Codable {
    var id = UUID()
    var name: String
    var dosage: String
    var time: String // HH:mm
}
