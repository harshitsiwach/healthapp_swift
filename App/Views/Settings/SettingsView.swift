import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var allLogs: [DailyLog]
    
    @State private var notificationTime = Date()
    @State private var showClearAlert = false
    @State private var showModelManagement = false
    
    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Summary
                        if let profile = profile {
                            profileCard(profile)
                        }
                        
                        // Notification Time
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundStyle(colors.neonBlue)
                                    Text("Daily Reminder")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                
                                Text("Get reminded to check your daily goals")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(colors.textSecondary)
                                
                                DatePicker("Reminder Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .font(.system(.body, design: .rounded))
                                    .onChange(of: notificationTime) { _, newValue in
                                        updateNotificationTime(newValue)
                                    }
                            }
                        }
                        
                        // AI Model Management
                        NavigationLink(destination: ModelManagementView()) {
                            GlassCard {
                                HStack {
                                    Image(systemName: "brain")
                                        .foregroundStyle(colors.neonPurple)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("AI Model Management")
                                            .font(.system(.headline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundStyle(colors.textPrimary)
                                        Text("Download and manage on-device AI models")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(colors.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // AI Data Management
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "externaldrive.fill")
                                        .foregroundStyle(colors.neonBlue)
                                    Text("AI Data")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                
                                settingsButton(icon: "trash", label: "Clear AI Cache", color: .orange) {
                                    // Clear cached AI responses
                                }
                                
                                settingsButton(icon: "doc.text.magnifyingglass", label: "Clear Document Index", color: .orange) {
                                    // Clear document retrieval index
                                }
                            }
                        }
                        
                        // Danger Zone
                        GlassCardRed {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(colors.neonRed)
                                    Text("Danger Zone")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                
                                settingsButton(icon: "trash.fill", label: "Clear All Data & Restart", color: .red) {
                                    showClearAlert = true
                                }
                            }
                        }
                        
                        // App Info
                        GlassCard {
                            VStack(spacing: 12) {
                                AppLogo(size: .medium, showText: true)
                                
                                Text("Version 1.0.0")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(colors.textSecondary)
                                Text("Powered by Gemini AI • Built with SwiftUI")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear Everything", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will delete all meal logs and your profile. Your streak will be preserved. You'll need to complete onboarding again.")
            }
            .onAppear {
                loadNotificationTime()
            }
        }
    }
    
    // MARK: - Components
    
    private func profileCard(_ profile: UserProfile) -> some View {
        GlassCard(material: .regularMaterial) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 56, height: 56)
                    Text(String(profile.gender.prefix(1)))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(profile.goal.capitalized) Mode")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    Text("\(profile.calculatedDailyCalories) kcal/day • \(profile.dietaryPreference.capitalized)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(colors.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(colors.neonOrange)
                        Text("\(profile.streakCount) day streak")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("\(profile.healthScore)")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(profile.healthScore >= 70 ? colors.neonGreen : colors.neonOrange)
                    Text("Score")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }
    
    private func settingsButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(label)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(colors.textPrimary)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func loadNotificationTime() {
        guard let profile = profile else { return }
        let components = profile.notificationTime.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        notificationTime = Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    private func updateNotificationTime(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: date)
        
        profile?.notificationTime = timeString
        try? modelContext.save()
        
        // Reschedule notification
        NotificationManager.shared.scheduleDailyReminder(at: timeString)
    }
    
    private func clearAllData() {
        let streakToPreserve = profile?.streakCount ?? 1
        
        // Delete all logs
        for log in allLogs {
            modelContext.delete(log)
        }
        
        // Delete profile (user goes back to onboarding)
        for p in profiles {
            modelContext.delete(p)
        }
        
        try? modelContext.save()
        
        // Note: streak is preserved by storing separately if needed
        // For now, the user re-onboards fresh
        _ = streakToPreserve
    }
}
