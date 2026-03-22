import Foundation
import SwiftData

/// Manages the behavioral leaderboard (not ranking by medical data)
@MainActor
final class LeaderboardService {
    static let shared = LeaderboardService()
    
    private init() {}
    
    func fetchGlobalLeaderboard(context: ModelContext) -> [LeaderboardEntry] {
        // Stub: In reality, fetch from remote backend.
        // We will mock a leaderboard containing the current user.
        
        let descriptor = FetchDescriptor<UserWellnessState>()
        let userState = try? context.fetch(descriptor).first
        let userScore = userState?.currentScore ?? 50.0
        let userLevel = userState?.currentLevel ?? 1
        let userRankLabel = XPService.shared.getRankName(for: userLevel)
        
        var mockEntries: [LeaderboardEntry] = [
            LeaderboardEntry(rank: 1, displayName: "FitnessGuru99", score: 98.4, level: 12, rankLabel: "Strong", isCurrentUser: false, trend: .same),
            LeaderboardEntry(rank: 2, displayName: "BalancedLife", score: 95.2, level: 9, rankLabel: "Balanced", isCurrentUser: false, trend: .up(places: 3)),
            LeaderboardEntry(rank: 3, displayName: "EarlyRiser", score: 91.0, level: 10, rankLabel: "Strong", isCurrentUser: false, trend: .down(places: 1)),
            LeaderboardEntry(rank: 4, displayName: "You", score: userScore, level: userLevel, rankLabel: userRankLabel, isCurrentUser: true, trend: .up(places: 12)),
            LeaderboardEntry(rank: 5, displayName: "WeekendWarrior", score: 85.5, level: 6, rankLabel: "Active", isCurrentUser: false, trend: .down(places: 2))
        ]
        
        // Sort by score
        mockEntries.sort { $0.score > $1.score }
        
        // Re-assign ranks based on array position
        return mockEntries.enumerated().map { (index, entry) in
            LeaderboardEntry(
                rank: index + 1,
                displayName: entry.displayName,
                score: entry.score,
                level: entry.level,
                rankLabel: entry.rankLabel,
                isCurrentUser: entry.isCurrentUser,
                trend: entry.trend
            )
        }
    }
}
