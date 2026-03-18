import Foundation
import UIKit
import EventKit
import UserNotifications
import ActivityKit

/// Central service to manage capabilities, request permissions, and store EventKit stores.
@MainActor
final class PermissionsService: ObservableObject {
    static let shared = PermissionsService()
    
    // The shared EventStore for the entire app
    let eventStore = EKEventStore()
    
    // Output states so the UI can adapt dynamically if a user hops to Settings
    @Published var hasCalendarFullAccess: Bool = false
    @Published var hasCalendarWriteOnlyAccess: Bool = false
    @Published var hasRemindersAccess: Bool = false
    @Published var hasNotificationAccess: Bool = false
    
    init() {
        checkCurrentStatus()
    }
    
    /// Checks the current authorization status without prompting the user
    func checkCurrentStatus() {
        if #available(iOS 17.0, *) {
            hasCalendarFullAccess = EKEventStore.authorizationStatus(for: .event) == .fullAccess
            hasCalendarWriteOnlyAccess = EKEventStore.authorizationStatus(for: .event) == .writeOnly
            hasRemindersAccess = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
        } else {
            hasCalendarFullAccess = EKEventStore.authorizationStatus(for: .event) == .authorized
            hasCalendarWriteOnlyAccess = hasCalendarFullAccess
            hasRemindersAccess = EKEventStore.authorizationStatus(for: .reminder) == .authorized
        }
        
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.hasNotificationAccess = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }
        }
    }
    
    // MARK: - Explicit Requests
    
    /// Requests write-only access to Calendar (best practice for just adding events)
    func requestCalendarWriteOnlyAccess() async throws -> Bool {
        if hasCalendarWriteOnlyAccess || hasCalendarFullAccess { return true }
        if #available(iOS 17.0, *) {
            let granted = try await eventStore.requestWriteOnlyAccessToEvents()
            self.hasCalendarWriteOnlyAccess = granted
            return granted
        } else {
            let granted = try await eventStore.requestAccess(to: .event)
            self.hasCalendarFullAccess = granted
            self.hasCalendarWriteOnlyAccess = granted
            return granted
        }
    }
    
    /// Requests full access to Calendar (only when we need to read/modify existing events)
    func requestCalendarFullAccess() async throws -> Bool {
        if hasCalendarFullAccess { return true }
        if #available(iOS 17.0, *) {
            let granted = try await eventStore.requestFullAccessToEvents()
            self.hasCalendarFullAccess = granted
            return granted
        } else {
            let granted = try await eventStore.requestAccess(to: .event)
            self.hasCalendarFullAccess = granted
            return granted
        }
    }
    
    /// Requests full access to Apple Reminders
    func requestRemindersAccess() async throws -> Bool {
        if hasRemindersAccess { return true }
        if #available(iOS 17.0, *) {
            let granted = try await eventStore.requestFullAccessToReminders()
            self.hasRemindersAccess = granted
            return granted
        } else {
            let granted = try await eventStore.requestAccess(to: .reminder)
            self.hasRemindersAccess = granted
            return granted
        }
    }
    
    /// Requests standard notification access (alerts, sounds, badges)
    func requestNotificationAccess() async throws -> Bool {
        if hasNotificationAccess { return true }
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        self.hasNotificationAccess = granted
        return granted
    }
    
    /// Utility to generate a deep link to Settings if needed
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
