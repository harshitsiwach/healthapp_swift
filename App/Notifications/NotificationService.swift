import Foundation
import UserNotifications

/// Service for managing local push notifications (hydration, sleep, meals, etc.)
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
    }
    
    private func setupCategories() {
        // Define actionable categories (e.g., Snooze, Mark Done)
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze 15m", options: [])
        let doneAction = UNNotificationAction(identifier: "DONE_ACTION", title: "Mark as Done", options: [.foreground])
        
        // Hydration category
        let hydrationCategory = UNNotificationCategory(identifier: "HYDRATION_CATEGORY",
                                                       actions: [doneAction, snoozeAction],
                                                       intentIdentifiers: [],
                                                       options: .customDismissAction)
        
        // Timer category
        let timerCategory = UNNotificationCategory(identifier: "TIMER_CATEGORY",
                                                   actions: [snoozeAction],
                                                   intentIdentifiers: [],
                                                   options: .customDismissAction)
        
        UNUserNotificationCenter.current().setNotificationCategories([hydrationCategory, timerCategory])
    }
    
    /// Schedules a precise countdown timer notification
    func scheduleTimerNotification(title: String, body: String, timeInterval: TimeInterval, identifier: String, category: String = "TIMER_CATEGORY") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        
        // Time interval must be > 0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 1), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule timer: \(error)")
            }
        }
    }
    
    /// Schedules a recurring date-based notification (e.g. daily medicine)
    func scheduleDailyNotification(title: String, body: String, hour: Int, minute: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Removes pending notifications by ID
    func cancelNotifications(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Delegate Actions
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let request = response.notification.request
        
        if action == "SNOOZE_ACTION" {
            // Re-schedule 15 minutes later
            scheduleTimerNotification(title: request.content.title,
                                      body: "Snoozed: \(request.content.body)",
                                      timeInterval: 15 * 60,
                                      identifier: UUID().uuidString,
                                      category: request.content.categoryIdentifier)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
