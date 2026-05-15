import Foundation
import UserNotifications

/// Service for managing local push notifications (hydration, sleep, meals, etc.)
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private override init() {
        super.init()
        // NOTE: Delegate is handled by NotificationManager to avoid conflicts.
        // Categories are also registered there to prevent overwriting.
    }
    
    // NOTE: Categories are now registered in NotificationManager.registerCategories()
    // to prevent overwriting the goal_check category.
    
    /// Called by NotificationManager when a snooze action is received
    func handleSnooze(for request: UNNotificationRequest) {
        scheduleTimerNotification(
            title: request.content.title,
            body: "Snoozed: \(request.content.body)",
            timeInterval: 15 * 60,
            identifier: UUID().uuidString,
            category: request.content.categoryIdentifier
        )
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
    

}
