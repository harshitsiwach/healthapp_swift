import Foundation
import SwiftData

/// Social graph functionality
@MainActor
final class FollowService {
    static let shared = FollowService()
    
    private init() {}
    
    func follow(profileId: UUID, context: ModelContext) {
        // Stub for adding a profile to the following list
        let descriptor = FetchDescriptor<PublicProfile>()
        guard let allProfiles = try? context.fetch(descriptor) else { return }
        
        if let p = allProfiles.first(where: { $0.id == profileId }) {
            p.isFollowing = true
            try? context.save()
        }
    }
    
    func unfollow(profileId: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<PublicProfile>()
        guard let allProfiles = try? context.fetch(descriptor) else { return }
        
        if let p = allProfiles.first(where: { $0.id == profileId }) {
            p.isFollowing = false
            try? context.save()
        }
    }
}
