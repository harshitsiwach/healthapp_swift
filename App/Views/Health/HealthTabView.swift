import SwiftUI
import SwiftData

struct HealthTabView: View {
    @Environment(\.theme) var colors
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyLog.date, order: .reverse) private var allLogs: [DailyLog]
    
    @StateObject private var viewModel = HealthReportViewModel()
    
    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            loadingView
                        } else if let report = viewModel.report {
                            reportView(report)
                        } else {
                            emptyView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel.report == nil && !viewModel.isLoading {
                    generateReport()
                }
            }
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 100)
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating Your Report...")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            Text("Analyzing your last 7 days of nutrition")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(colors.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Report
    
    private func reportView(_ report: HealthReportResult) -> some View {
        VStack(spacing: 20) {
            // Health Score
            GlassCard(material: .regularMaterial, cornerRadius: 28, padding: 28) {
                VStack(spacing: 16) {
                    Text("Health Score")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(colors.textSecondary)
                    
                    CircularProgressView(
                        progress: Double(report.score) / 10.0,
                        lineWidth: 16,
                        size: 140,
                        progressColor: report.score >= 7 ? colors.neonGreen : report.score >= 4 ? colors.neonOrange : colors.neonRed
                    )
                    .overlay {
                        Text("\(report.score)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(report.score >= 7 ? colors.neonGreen : report.score >= 4 ? colors.neonOrange : colors.neonRed)
                    }
                    
                    Text("out of 10")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(colors.textSecondary)
                    
                    Text(report.summary)
                        .font(.system(.subheadline, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(colors.textSecondary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Warnings
            if !report.warnings.isEmpty {
                GlassCardYellow {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(colors.neonYellow)
                            Text("Health Warnings")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                        }
                        
                        ForEach(report.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(colors.neonOrange)
                                    .padding(.top, 3)
                                Text(warning)
                                    .font(.system(.subheadline, design: .rounded))
                            }
                        }
                    }
                }
            }
            
            // Natural Remedies
            if !report.naturalCures.isEmpty {
                GlassCardGreen {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(colors.neonGreen)
                            Text("Natural Remedies")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                        }
                        
                        ForEach(report.naturalCures, id: \.name) { cure in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🌿 \(cure.name)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                Text(cure.benefit)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(colors.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            // Regenerate
            Button {
                generateReport()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate Report")
                }
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(colors.neonBlue)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Empty
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 80)
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 60))
                .foregroundStyle(colors.textSecondary)
            Text("No Report Yet")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.heavy)
            Text("Log meals for a few days to get your weekly health report")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                generateReport()
            } label: {
                Text("Generate Report")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(colors.neonBlue.gradient, in: Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
    
    // MARK: - Generate
    
    private func generateReport() {
        guard let profile = profile else { return }
        
        let last7Days = last7DayLogs
        let avgCalories = last7Days.isEmpty ? 0 : last7Days.reduce(0) { $0 + $1.estimatedCalories } / max(last7Days.count, 1)
        let avgProtein = last7Days.isEmpty ? 0 : last7Days.reduce(0.0) { $0 + $1.proteinG } / Double(max(last7Days.count, 1))
        let avgCarbs = last7Days.isEmpty ? 0 : last7Days.reduce(0.0) { $0 + $1.carbsG } / Double(max(last7Days.count, 1))
        let avgFat = last7Days.isEmpty ? 0 : last7Days.reduce(0.0) { $0 + $1.fatG } / Double(max(last7Days.count, 1))
        
        let goalLogs = allLogs.filter { $0.goalCompleted != nil }
        let completedCount = goalLogs.filter { $0.goalCompleted == 1 }.count
        let goalRate = goalLogs.isEmpty ? 0 : Double(completedCount) / Double(goalLogs.count)
        
        viewModel.generate(
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            avgCarbs: avgCarbs,
            avgFat: avgFat,
            goalCompletionRate: goalRate,
            userGoal: profile.goal,
            dietaryPreference: profile.dietaryPreference
        )
    }
    
    private var last7DayLogs: [DailyLog] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let sevenDaysAgo = formatter.string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())
        
        return allLogs.filter {
            $0.date >= sevenDaysAgo && $0.date <= today && $0.foodName != nil
        }
    }
}
