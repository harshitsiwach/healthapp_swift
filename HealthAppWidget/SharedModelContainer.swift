import Foundation
import SwiftData

// MARK: - Shared Model Container
// Use this in BOTH the main app and widget extension to share data via App Groups.

extension ModelContainer {
    static func shared() -> ModelContainer {
        let schema = Schema([UserProfile.self, DailyLog.self])
        
        // App Group container for sharing between app and widget
        let appGroupID = "group.com.aihealthappoffline.shared"
        
        // Fallback to local storage if the App Group is not available (common during testing/simulator)
        let modelConfiguration: ModelConfiguration
        
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupID),
                cloudKitDatabase: .none
            )
        } else {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .none
            )
        }
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }
}
