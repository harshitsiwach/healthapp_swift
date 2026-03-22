import SwiftUI
import SwiftData

struct SocialDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query private var wellnessStates: [UserWellnessState]
    
    var wellnessState: UserWellnessState? { wellnessStates.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile Summary Card
                        NavigationLink(destination: PublicProfileView(profileId: wellnessState?.id ?? UUID())) {
                            GlassCard {
                                HStack(spacing: 16) {
                                    AppLogo(size: .small)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(profiles.first?.name ?? "My Profile")
                                            .font(.headline)
                                        Text("Level \(wellnessState?.currentLevel ?? 1) • \(XPService.shared.getRankName(for: wellnessState?.currentLevel ?? 1))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "person.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.blue)
                                }
                                .padding()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Wellness Bar (Mini version or re-use)
                        WellnessBarCard()
                        
                        // Quests & Challenges Shortcuts
                        HStack(spacing: 15) {
                            SocialShortcutCard(title: "Quests", icon: "star.fill", color: .yellow, destination: AnyView(QuestCenterView()))
                            SocialShortcutCard(title: "Challenges", icon: "figure.run", color: .green, destination: AnyView(ChallengesView()))
                        }
                        
                        // Leaderboard Preview
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Leaderboard")
                                    .font(.headline)
                                Spacer()
                                NavigationLink("View All", destination: LeaderboardView())
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.blue)
                            }
                            
                            LeaderboardPreviewList()
                        }
                        
                        // Shared Routines
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Daily Routines")
                                .font(.headline)
                            
                            RoutinePreviewCarousel()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: PrivacySettingsView()) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct SocialShortcutCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            GlassCard {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(.plain)
    }
}

struct LeaderboardPreviewList: View {
    @Environment(\.modelContext) private var context
    @State private var topEntries: [LeaderboardEntry] = []
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(topEntries.prefix(3)) { entry in
                GlassCard(padding: 12) {
                    HStack {
                        Text("\(entry.rank)")
                            .font(.subheadline.bold())
                            .frame(width: 20)
                        Text(entry.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(entry.score))")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .onAppear {
            topEntries = LeaderboardService.shared.fetchGlobalLeaderboard(context: context)
        }
    }
}

struct RoutinePreviewCarousel: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(0..<3) { i in
                    GlassCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Elite Flow #\(i+1)")
                                .font(.subheadline.bold())
                            Text("Wake 6:00 AM • 12k Steps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("View") {
                                // Navigate to template
                            }
                            .font(.caption.bold())
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .clipShape(Capsule())
                        }
                    }
                    .frame(width: 200)
                }
            }
        }
    }
}



#Preview {
    SocialDashboardView()
}
