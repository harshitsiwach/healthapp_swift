import Foundation
import EventKit
import EventKitUI

/// Service to interact directly with Apple's EventKit for creating/fetching calendar events
@MainActor
final class CalendarService {
    static let shared = CalendarService()
    
    // Use the shared event store established in PermissionsService
    private var eventStore: EKEventStore { PermissionsService.shared.eventStore }
    
    /// Silent background creation (requires write access)
    func addEventBACKGROUND(title: String,
                            startDate: Date,
                            endDate: Date,
                            notes: String? = nil,
                            url: URL? = nil) throws -> String {
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.url = url
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add a default 15-minute alert if it's an important health appointment
        let alarm = EKAlarm(relativeOffset: -15 * 60)
        event.addAlarm(alarm)
        
        try eventStore.save(event, span: .thisEvent, commit: true)
        return event.eventIdentifier ?? ""
    }
    
    /// Pre-populate an EKEvent that we can pass to the native EKEventEditViewController
    func draftEvent(title: String,
                    startDate: Date,
                    endDate: Date,
                    notes: String? = nil) -> EKEvent {
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        
        let alarm = EKAlarm(relativeOffset: -15 * 60)
        event.addAlarm(alarm)
        return event
    }
    
    /// Fetches events matching a specific predicate (requires Full Access)
    func fetchUpcomingEvents(daysAhead: Int = 14) throws -> [EKEvent] {
        guard PermissionsService.shared.hasCalendarFullAccess else {
            throw NSError(domain: "CalendarService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Full Calendar access is missing."])
        }
        
        let start = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: daysAhead, to: start) else { return [] }
        
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
    
    /// Deletes an event by passing the EKEvent directly
    func deleteEvent(_ event: EKEvent) throws {
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }
}
