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
        .modelContainer(ModelContainer.shared())
    }
    
    private func handleGoalNotification(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let date = userInfo["date"] as? String,
              let completed = userInfo["completed"] as? Bool else { return }
        
        let descriptor = FetchDescriptor<UserProfile>()
        
        _ = date
        _ = completed
    }
}
