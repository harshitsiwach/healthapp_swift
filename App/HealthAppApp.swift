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
        
        let container = ModelContainer.shared()
        let context = ModelContext(container)
        
        var descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.date == date
            }
        )
        descriptor.fetchLimit = 1
        
        do {
            let logs = try context.fetch(descriptor)
            if let existingLog = logs.first {
                existingLog.goalCompleted = completed ? 1 : 0
            } else {
                let newLog = DailyLog(date: date, goalCompleted: completed ? 1 : 0)
                context.insert(newLog)
            }
            try context.save()
        } catch {
            print("Failed to save goal completion: \(error)")
        }
    }
}
