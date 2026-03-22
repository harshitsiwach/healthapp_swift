import SwiftUI

struct LeaderboardView: View {
    @Environment(\.modelContext) private var context
    @State private var entries: [LeaderboardEntry] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    // Top 3 Podium
                    if entries.count >= 3 {
                        HStack(alignment: .bottom, spacing: 20) {
                            PodiumPillar(entry: entries[1], height: 120, rank: 2, color: .gray)
                            PodiumPillar(entry: entries[0], height: 160, rank: 1, color: .yellow)
                            PodiumPillar(entry: entries[2], height: 100, rank: 3, color: .brown)
                        }
                        .padding(.vertical, 30)
                    }
                    
                    // List
                    VStack(spacing: 10) {
                        ForEach(entries) { entry in
                            LeaderboardRow(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(GradientBackground())
            .navigationTitle("Leaderboard")
            .onAppear {
                entries = LeaderboardService.shared.fetchGlobalLeaderboard(context: context)
            }
        }
    }
}

struct PodiumPillar: View {
    let entry: LeaderboardEntry
    let height: CGFloat
    let rank: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(entry.displayName)
                .font(.caption)
                .lineLimit(1)
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [color.opacity(0.8), color.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 70, height: height)
                
                Text("\(rank)")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 10)
            }
            
            Text("\(Int(entry.score))")
                .font(.caption.bold())
                .foregroundStyle(color)
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        GlassCard {
            HStack(spacing: 15) {
                Text("\(entry.rank)")
                    .font(.headline)
                    .frame(width: 30, alignment: .center)
                    .foregroundStyle(entry.rank <= 3 ? .primary : .secondary)
                
                VStack(alignment: .leading) {
                    Text(entry.displayName + (entry.isCurrentUser ? " (You)" : ""))
                        .font(.headline)
                        .foregroundStyle(entry.isCurrentUser ? Color.accentColor : Color.primary)
                    Text("\(entry.rankLabel) • Lvl \(entry.level)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Trend Arrow
                Group {
                    switch entry.trend {
                    case .up(let places):
                        Label("\(places)", systemImage: "arrow.up")
                            .foregroundStyle(.green)
                    case .down(let places):
                        Label("\(places)", systemImage: "arrow.down")
                            .foregroundStyle(.red)
                    case .same:
                        Image(systemName: "minus")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption.bold())
                .frame(width: 40, alignment: .trailing)
                
                Text("\(Int(entry.score))")
                    .font(.headline.weight(.heavy))
                    .frame(width: 40, alignment: .trailing)
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(entry.isCurrentUser ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    LeaderboardView()
}
