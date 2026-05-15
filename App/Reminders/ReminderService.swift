import Foundation
import EventKit

/// Service for interacting directly with Apple Reminders via EventKit
@MainActor
final class ReminderService {
    static let shared = ReminderService()
    
    private var eventStore: EKEventStore { PermissionsService.shared.eventStore }
    
    /// Creates a reminder and saves it to the default reminders list.
    /// This requires Full Access to Reminders.
    func createReminder(title: String,
                        notes: String? = nil,
                        dueDate: Date? = nil,
                        priority: Int = 0) throws -> String {
        guard PermissionsService.shared.hasRemindersAccess else {
            throw NSError(domain: "ReminderService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Reminders access is missing."])
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.priority = priority
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        if let dueDate = dueDate {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.dueDateComponents = components
            
            // Also add an absolute alarm to fire at the time
            let alarm = EKAlarm(absoluteDate: dueDate)
            reminder.addAlarm(alarm)
        }
        
        try eventStore.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }
    
    /// Fetches all incomplete reminders in the default list
    func fetchIncompleteReminders() async throws -> [EKReminder] {
        guard PermissionsService.shared.hasRemindersAccess else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let calendar = eventStore.defaultCalendarForNewReminders() else {
                continuation.resume(returning: [])
                return
            }
            
            let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [calendar])
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    /// Marks a reminder as complete
    func completeReminder(_ reminder: EKReminder) throws {
        reminder.isCompleted = true
        reminder.completionDate = Date()
        try eventStore.save(reminder, commit: true)
    }
    
    /// Deletes a reminder
    func deleteReminder(_ reminder: EKReminder) throws {
        try eventStore.remove(reminder, commit: true)
    }
}
