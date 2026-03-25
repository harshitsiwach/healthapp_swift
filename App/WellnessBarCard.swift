import SwiftUI
import SwiftData

struct WellnessBarCard: View {
    @Environment(\.modelContext) private var context
    @Query private var states: [UserWellnessState]
    
    var wellnessState: UserWellnessState? { states.first }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Wellness Bar")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(XPService.shared.getRankName(for: wellnessState?.currentLevel ?? 1))
                            .font(.title2.bold())
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Level \(wellnessState?.currentLevel ?? 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(PerplexityTheme.accent)
                        Text("XP: \(wellnessState?.totalXP ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Animated Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(height: 24)
                        
                        Capsule()
                            .fill(
                                LinearGradient(colors: [PerplexityTheme.accent, PerplexityTheme.accentSecondary], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat((wellnessState?.currentScore ?? 50.0) / 100.0))), height: 24)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: wellnessState?.currentScore)
                    }
                }
                .frame(height: 24)
                
                // Footer Stats
                HStack {
                    Label("\(Int(wellnessState?.currentScore ?? 50.0))", systemImage: "bolt.heart.fill")
                        .foregroundStyle(PerplexityTheme.accent)
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    Label("\(wellnessState?.currentStreakDays ?? 0) Day Streak", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline.bold())
                }
            }
            .padding()
        }
    }
}

#Preview {
    WellnessBarCard()
        .modelContainer(for: UserWellnessState.self, inMemory: true)
}
