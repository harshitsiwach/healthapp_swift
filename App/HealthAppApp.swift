import SwiftUI
import SwiftData

@main
struct HealthAppApp: App {
    let notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .onReceive(NotificationCenter.default.publisher(for: .goalCompletedFromNotification)) { notification in
                    handleGoalNotification(notification)
                }
        }
        .modelContainer(for: [UserProfile.self, DailyLog.self])
    }
    
    private func handleGoalNotification(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let date = userInfo["date"] as? String,
              let completed = userInfo["completed"] as? Bool else { return }
        
        // This will be handled by the model context in the active scene
        // For background writes, we need to create a separate model context
        let descriptor = FetchDescriptor<UserProfile>()
        
        // Post to the main UI for now — the dashboard handles this
        _ = date
        _ = completed
    }
}
