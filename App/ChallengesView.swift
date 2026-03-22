import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Environment(\.modelContext) private var context
    @Query private var allChallenges: [Challenge]
    
    var activeChallenges: [Challenge] {
        allChallenges.filter { $0.endDate >= Date() }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if activeChallenges.isEmpty {
                        ContentUnavailableView("No Active Challenges", systemImage: "flag.slash", description: Text("Check back later for new community sprints."))
                    } else {
                        ForEach(activeChallenges) { challenge in
                            ChallengeCard(challenge: challenge)
                        }
                    }
                }
                .padding()
            }
            .background(GradientBackground())
            .navigationTitle("Community Challenges")
            .onAppear {
                ChallengeService.shared.fetchActiveChallenges(context: context)
            }
        }
    }
}

struct ChallengeCard: View {
    @Environment(\.modelContext) private var context
    let challenge: Challenge
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 50, height: 50)
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.headline)
                        Text("\(challenge.participantCount) participants")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    if challenge.isJoined {
                        Label("Joined", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text(challenge.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Label("Ends \(challenge.endDate, format: .dateTime.month().day())", systemImage: "clock")
                        .font(.caption.bold())
                    Spacer()
                    Label("+\(challenge.xpReward) XP", systemImage: "star.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                }
                
                if !challenge.isJoined {
                    Button(action: {
                        withAnimation {
                            ChallengeService.shared.joinChallenge(id: challenge.id, context: context)
                        }
                    }) {
                        Text("Join Challenge")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 5)
                } else {
                    // Progress Indicator
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Progress")
                            .font(.caption.bold())
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.secondary.opacity(0.2))
                                    .frame(height: 10)
                                Capsule().fill(Color.accentColor)
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(challenge.userProgress) / CGFloat(max(1, challenge.targetValue)))), height: 10)
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
        }
    }
}
