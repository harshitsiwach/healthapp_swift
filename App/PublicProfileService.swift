import Foundation
import SwiftData

/// Manages opt-in public profiles safely
@MainActor
final class PublicProfileService {
    static let shared = PublicProfileService()
    
    private init() {}
    
    /// Stub function to get the user's public profile if they opted in
    func getMyPublicProfile(context: ModelContext) -> PublicProfile? {
        let descriptor = FetchDescriptor<PublicProfile>()
        return try? context.fetch(descriptor).first
    }
    
    /// Publish profile (requires Private/Friends/Public selection)
    func publishProfile(displayName: String, bio: String, context: ModelContext) {
        let descriptor = FetchDescriptor<PublicProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        
        if let existing = profiles.first {
            existing.displayName = displayName
            existing.bio = bio
        } else {
            // Assume we fetch actual wellness data
            let wellnessDesc = FetchDescriptor<UserWellnessState>()
            let wState = try? context.fetch(wellnessDesc).first
            
            let profile = PublicProfile(
                displayName: displayName,
                bio: bio,
                level: wState?.currentLevel ?? 1,
                rank: XPService.shared.getRankName(for: wState?.currentLevel ?? 1),
                currentScore: wState?.currentScore ?? 50.0
            )
            context.insert(profile)
        }
        try? context.save()
    }
}
