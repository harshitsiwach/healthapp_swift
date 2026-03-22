import Foundation
import SwiftData

@Model
final class Challenge {
    var id: UUID
    var title: String
    var descriptionText: String
    var startDate: Date
    var endDate: Date
    var participantCount: Int
    var xpReward: Int
    var badgeReward: String?
    var targetValue: Int // e.g., 70000 for a 10k steps/week challenge
    var type: String
    
    // User progress locally
    var isJoined: Bool
    var userProgress: Int
    
    init(id: UUID = UUID(), title: String, descriptionText: String, startDate: Date, endDate: Date, participantCount: Int, xpReward: Int, badgeReward: String? = nil, targetValue: Int, type: String, isJoined: Bool = false, userProgress: Int = 0) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.startDate = startDate
        self.endDate = endDate
        self.participantCount = participantCount
        self.xpReward = xpReward
        self.badgeReward = badgeReward
        self.targetValue = targetValue
        self.type = type
        self.isJoined = isJoined
        self.userProgress = userProgress
    }
}

/// Manages community sprints
@MainActor
final class ChallengeService {
    static let shared = ChallengeService()
    
    private init() {}
    
    func fetchActiveChallenges(context: ModelContext) {
        // Stub: Fetch from remote backend in real app.
        // For local demo, populate if empty
        let descriptor = FetchDescriptor<Challenge>()
        if (try? context.fetch(descriptor))?.isEmpty == true {
            let start = Date()
            let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
            
            let c1 = Challenge(title: "10k Steps Week", descriptionText: "Hit 10,000 steps every day this week with the community.", startDate: start, endDate: end, participantCount: 1452, xpReward: 500, badgeReward: "10k_week", targetValue: 70000, type: "steps")
            
            let c2 = Challenge(title: "Hydration Sprint", descriptionText: "Log your full water goal 5 times this week.", startDate: start, endDate: end, participantCount: 340, xpReward: 200, targetValue: 5, type: "hydrate")
            
            context.insert(c1)
            context.insert(c2)
            try? context.save()
        }
    }
    
    func joinChallenge(id: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<Challenge>()
        guard let all = try? context.fetch(descriptor) else { return }
        
        if let challenge = all.first(where: { $0.id == id }) {
            challenge.isJoined = true
            challenge.participantCount += 1
            try? context.save()
        }
    }
}
