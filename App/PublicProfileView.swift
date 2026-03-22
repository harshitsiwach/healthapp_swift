import SwiftUI
import SwiftData

struct PublicProfileView: View {
    @Environment(\.modelContext) private var context
    let profileId: UUID // Real app would fetch by ID
    
    // Stub profile data
    @State private var profile: PublicProfile?
    
    var body: some View {
        ScrollView {
            if let target = profile {
                VStack(spacing: 20) {
                    // Hero Header
                    VStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.accentColor.opacity(0.5), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 100, height: 100)
                            if let avatar = target.avatarURL {
                                // Image fetch...
                            } else {
                                Text(String(target.displayName.prefix(1)))
                                    .font(.system(size: 40, weight: .bold))
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(target.displayName)
                                .font(.title.bold())
                            Text(target.bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 30) {
                            VStack {
                                Text(target.rank)
                                    .font(.headline)
                                Text("Rank")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(target.level)")
                                    .font(.headline)
                                Text("Level")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button {
                            // Follow Action
                            if target.isFollowing {
                                FollowService.shared.unfollow(profileId: target.id, context: context)
                            } else {
                                FollowService.shared.follow(profileId: target.id, context: context)
                            }
                            // Refresh
                            target.isFollowing.toggle()
                        } label: {
                            Text(target.isFollowing ? "Following" : "Follow")
                                .font(.headline)
                                .frame(width: 160)
                                .padding(.vertical, 10)
                                .background(target.isFollowing ? Color(uiColor: .tertiarySystemFill) : Color.accentColor)
                                .foregroundStyle(target.isFollowing ? Color.primary : Color.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    
                    // Badges Grid
                    GlassCard {
                        VStack(alignment: .leading) {
                            Text("Recent Badges")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    // Stub
                                    BadgeIcon(symbol: "flame.fill", color: .orange, title: "7 Days")
                                    BadgeIcon(symbol: "chart.pie.fill", color: .green, title: "Balanced")
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Shared Routine
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Public Routine", systemImage: "doc.text.image")
                                    .font(.headline)
                                Spacer()
                                Button("Copy") {
                                    // Copy action triggered
                                }
                                .font(.subheadline.bold())
                                .buttonStyle(.borderedProminent)
                                .tint(.accentColor)
                                .clipShape(Capsule())
                            }
                            
                            Text("Wake: 06:30 • Steps: 10k • Hydration: 3L")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                }
            } else {
                ProgressView()
            }
        }
        .background(GradientBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Stub fetch
            self.profile = PublicProfile(displayName: "FitnessGuru99", bio: "Consistency is key. 10k steps daily.", level: 12, rank: "Strong", currentScore: 98.4, isFollowing: false)
        }
    }
}

struct BadgeIcon: View {
    let symbol: String
    let color: Color
    let title: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .font(.system(size: 24))
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
