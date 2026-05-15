import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await MainActor.run {
            isAuthorized = granted
        }
    }
    
    // MARK: - Categories & Actions
    
    func registerCategories() {
        let yesAction = UNNotificationAction(
            identifier: "GOAL_YES",
            title: "Yes, absolutely!",
            options: [.foreground]
        )
        
        let noAction = UNNotificationAction(
            identifier: "GOAL_NO",
            title: "Not yet",
            options: [.destructive]
        )
        
        let goalCategory = UNNotificationCategory(
            identifier: "goal_check",
            actions: [yesAction, noAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Hydration & Timer categories (consolidated from NotificationService)
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze 15m", options: [])
        let doneAction = UNNotificationAction(identifier: "DONE_ACTION", title: "Mark as Done", options: [.foreground])
        
        let hydrationCategory = UNNotificationCategory(
            identifier: "HYDRATION_CATEGORY",
            actions: [doneAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_CATEGORY",
            actions: [snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        center.setNotificationCategories([goalCategory, hydrationCategory, timerCategory])
    }
    
    // MARK: - Schedule Daily Reminder
    
    func scheduleDailyReminder(at timeString: String) {
        // Remove existing reminders
        center.removePendingNotificationRequests(withIdentifiers: ["daily_goal_check"])
        
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Check 🎯"
        content.body = "Did you complete your health goals today? Tap to answer!"
        content.sound = .default
        content.categoryIdentifier = "goal_check"
        
        let request = UNNotificationRequest(
            identifier: "daily_goal_check",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }
    
    // MARK: - Handle Goal Response
    
    func handleGoalResponse(completed: Bool) {
        // This will be called from the notification delegate
        // Write to SwiftData in the background
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        // Post notification for the app to handle DB write
        NotificationCenter.default.post(
            name: .goalCompletedFromNotification,
            object: nil,
            userInfo: ["date": today, "completed": completed]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "GOAL_YES":
            handleGoalResponse(completed: true)
        case "GOAL_NO":
            handleGoalResponse(completed: false)
        case "SNOOZE_ACTION":
            NotificationService.shared.handleSnooze(for: response.notification.request)
        case "DONE_ACTION":
            break // Mark as done — handled by app foreground
        default:
            break
        }
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let goalCompletedFromNotification = Notification.Name("goalCompletedFromNotification")
}
