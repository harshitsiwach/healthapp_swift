import SwiftUI
import HealthKit

// MARK: - Apple Health Sync View

struct HealthSyncView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    
    @State private var isAuthorized = false
    @State private var isImporting = false
    @State private var steps = 0
    @State private var sleepHours = 0.0
    @State private var latestHR: Int?
    @State private var latestWeight: Double?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "heart.ring.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(colors.neonRed.gradient)
                    
                    Text("Apple Health")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(colors.textPrimary)
                    
                    Text("Sync your steps, sleep, heart rate, and weight from the Apple Health app to get a complete picture of your health.")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Divider()
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundStyle(isAuthorized ? colors.neonGreen : colors.neonYellow)
                        Text(isAuthorized ? "Connected" : "Not Connected")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(colors.textPrimary)
                    }
                    
                    if isAuthorized {
                        Text("Apple Health is connected. Import data anytime.")
                            .font(.caption)
                            .foregroundStyle(colors.textSecondary)
                    } else {
                        Text("Tap 'Connect' to grant permission")
                            .font(.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(colors.backgroundCard))
                .padding(.horizontal)
                
                Button {
                    Task {
                        await importFromHealth()
                    }
                } label: {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .tint(.white)
                        }
                        Image(systemName: "arrow.clockwise")
                        Text(isAuthorized ? (isImporting ? "Importing..." : "Import Now") : "Connect Apple Health")
                    }
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isAuthorized ? colors.neonGreen.gradient : colors.neonBlue.gradient)
                    )
                }
                .padding(.horizontal)
                .disabled(isImporting)
                
                if isAuthorized && !isImporting {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Latest Data")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(colors.textSecondary)
                        
                        HStack(spacing: 16) {
                            HealthStatTile(title: "Steps", value: "\(steps)", icon: "figure.walk", color: colors.neonGreen)
                            HealthStatTile(title: "Sleep", value: String(format: "%.1fh", sleepHours), icon: "bed.double.fill", color: colors.neonBlue)
                        }
                        
                        HStack(spacing: 16) {
                            if let hr = latestHR {
                                HealthStatTile(title: "Heart Rate", value: "\(hr)", unit: "bpm", icon: "heart.fill", color: colors.neonRed)
                            }
                            if let w = latestWeight {
                                HealthStatTile(title: "Weight", value: String(format: "%.1f", w), unit: "kg", icon: "scalemass.fill", color: colors.neonYellow)
                            }
                        }
                    }
                    .padding()
                    .themedCard()
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Text("Health data is stored locally on your device only. We never share it.")
                    .font(.caption2)
                    .foregroundStyle(colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            .padding(.top)
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Health Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
            .onAppear {
                Task {
                    isAuthorized = await checkAuthorization()
                    if isAuthorized {
                        await fetchLatestHealthData()
                    }
                }
            }
            .alert("Health Sync", isPresented: $showingSuccess) {
                Button("OK") { }
            } message: {
                Text("Successfully imported \(steps) steps, \(String(format: "%.1f", sleepHours))h sleep, and other health data to your daily log.")
            }
        }
    }
    
    // MARK: - Private
    
    private func checkAuthorization() async -> Bool {
        do {
            return try await HealthManager.shared.requestAuthorization()
        } catch {
            return false
        }
    }
    
    private func fetchLatestHealthData() async {
        steps = await HealthManager.shared.fetchTodaySteps() ?? 0
        sleepHours = await HealthManager.shared.fetchTodaySleep() ?? 0
        latestHR = await HealthManager.shared.fetchLatestHeartRate()
        latestWeight = await HealthManager.shared.fetchLatestWeight()
    }
    
    private func importFromHealth() async {
        isImporting = true
        
        do {
            let fetchedSteps = await HealthManager.shared.fetchTodaySteps() ?? 0
            let fetchedSleep = await HealthManager.shared.fetchTodaySleep() ?? 0
            let fetchedHR = await HealthManager.shared.fetchLatestHeartRate()
            let fetchedWeight = await HealthManager.shared.fetchLatestWeight()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.string(from: Date())
            
            let sleepMinutes = Int(fetchedSleep * 60) % 60
            let log = DailyLog(
                date: date,
                foodName: nil,
                estimatedCalories: 0,
                proteinG: 0,
                carbsG: 0,
                fatG: 0,
                steps: fetchedSteps,
                sleepHours: fetchedSleep,
                sleepMinutes: sleepMinutes,
                heartRate: fetchedHR,
                waterML: 0,
                hrvMs: nil,
                stressLevel: nil
            )
            modelContext.insert(log)
            try? modelContext.save()
            
            steps = fetchedSteps
            sleepHours = fetchedSleep
            latestHR = fetchedHR
            latestWeight = fetchedWeight
            
            isImporting = false
            showingSuccess = true
            
        } catch {
            isImporting = false
        }
    }
}

// MARK: - Stat Tile

struct HealthStatTile: View {
    let title: String
    let value: String
    var unit: String = ""
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(value.isEmpty ? .secondary : .primary)
                .monospacedDigit()
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground).opacity(0.5)))
    }
}
