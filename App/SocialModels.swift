import Foundation
import SwiftData

// MARK: - Privacy Settings
@Model
final class PrivacySettings {
    var id: UUID
    var visibility: String // "private", "friends", "public"
    var shareRoutines: Bool
    var participateInLeaderboards: Bool
    var showBadges: Bool
    
    init(id: UUID = UUID(), visibility: String = "private", shareRoutines: Bool = false, participateInLeaderboards: Bool = false, showBadges: Bool = true) {
        self.id = id
        self.visibility = visibility
        self.shareRoutines = shareRoutines
        self.participateInLeaderboards = participateInLeaderboards
        self.showBadges = showBadges
    }
}

// MARK: - Public Profile
@Model
final class PublicProfile {
    var id: UUID
    var displayName: String
    var bio: String
    var avatarURL: String?
    var level: Int
    var rank: String
    var currentScore: Double
    var isFollowing: Bool
    
    init(id: UUID = UUID(), displayName: String, bio: String, avatarURL: String? = nil, level: Int, rank: String, currentScore: Double, isFollowing: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
        self.level = level
        self.rank = rank
        self.currentScore = currentScore
        self.isFollowing = isFollowing
    }
}

// MARK: - Routine Template
@Model
final class RoutineTemplate {
    var id: UUID
    var authorName: String
    var title: String
    var descriptionText: String
    var wakeTime: String // HH:mm
    var sleepTime: String // HH:mm
    var hydrationGoalLiters: Double
    var stepGoal: Int
    var mealCadence: Int // meals per day
    
    // Social mechanics
    var copyCount: Int
    var isUserActiveRoutine: Bool
    
    init(id: UUID = UUID(), authorName: String, title: String, descriptionText: String, wakeTime: String, sleepTime: String, hydrationGoalLiters: Double, stepGoal: Int, mealCadence: Int, copyCount: Int = 0, isUserActiveRoutine: Bool = false) {
        self.id = id
        self.authorName = authorName
        self.title = title
        self.descriptionText = descriptionText
        self.wakeTime = wakeTime
        self.sleepTime = sleepTime
        self.hydrationGoalLiters = hydrationGoalLiters
        self.stepGoal = stepGoal
        self.mealCadence = mealCadence
        self.copyCount = copyCount
        self.isUserActiveRoutine = isUserActiveRoutine
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    let rank: Int
    let displayName: String
    let score: Double
    let level: Int
    let rankLabel: String
    let isCurrentUser: Bool
    let trend: TrendDirection
    
    enum TrendDirection: Hashable, Equatable {
        case up(places: Int)
        case down(places: Int)
        case same
    }
}
