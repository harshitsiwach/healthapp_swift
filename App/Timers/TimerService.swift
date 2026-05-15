import Foundation
import SwiftUI
import Combine

/// Manages in-app timers (like fasting windows or cooking) and syncs them with Local Notifications
@MainActor
final class TimerService: ObservableObject {
    static let shared = TimerService()
    
    @Published var activeTimers: [String: TimeInterval] = [:] // id -> remaining seconds
    private var timerCancellables: [String: AnyCancellable] = [:]
    
    /// Starts a timer, updates UI state every second, and schedules a backup local notification
    func startTimer(id: String, title: String, duration: TimeInterval) {
        // 1. Schedule the notification backup
        NotificationService.shared.scheduleTimerNotification(
            title: title,
            body: "Your \(title) timer is done!",
            timeInterval: duration,
            identifier: id
        )
        
        // 2. Setup local publisher for UI counting
        activeTimers[id] = duration
        let publisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
        let targetDate = Date().addingTimeInterval(duration)
        
        timerCancellables[id] = publisher.sink { [weak self] _ in
            guard let self = self else { return }
            let remaining = targetDate.timeIntervalSince(Date())
            
            if remaining <= 0 {
                self.activeTimers.removeValue(forKey: id)
                self.timerCancellables[id]?.cancel()
                self.timerCancellables.removeValue(forKey: id)
                
                // End Live Activity if present
                LiveActivityService.shared.endActivity(for: id)
            } else {
                self.activeTimers[id] = remaining
            }
        }
        
        // 3. (Optional) Start Live Activity
        LiveActivityService.shared.startActivity(id: id, title: title, endDate: targetDate)
    }
    
    /// Cancels a timer and its linked notification
    func cancelTimer(id: String) {
        timerCancellables[id]?.cancel()
        timerCancellables.removeValue(forKey: id)
        activeTimers.removeValue(forKey: id)
        
        NotificationService.shared.cancelNotifications(identifiers: [id])
        LiveActivityService.shared.endActivity(for: id)
    }
}
