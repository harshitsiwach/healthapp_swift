import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct HealthWidgetEntry: TimelineEntry {
    let date: Date
    let caloriesEaten: Int
    let caloriesTarget: Int
    let proteinEaten: Double
    let proteinTarget: Double
    let carbsEaten: Double
    let carbsTarget: Double
    let fatEaten: Double
    let fatTarget: Double
    let streakCount: Int
    let healthScore: Int
    
    static var placeholder: HealthWidgetEntry {
        HealthWidgetEntry(
            date: Date(),
            caloriesEaten: 1200,
            caloriesTarget: 2545,
            proteinEaten: 65,
            proteinTarget: 159,
            carbsEaten: 180,
            carbsTarget: 318,
            fatEaten: 35,
            fatTarget: 70,
            streakCount: 5,
            healthScore: 72
        )
    }
    
    static var snapshot: HealthWidgetEntry {
        HealthWidgetEntry(
            date: Date(),
            caloriesEaten: 1800,
            caloriesTarget: 2545,
            proteinEaten: 95,
            proteinTarget: 159,
            carbsEaten: 220,
            carbsTarget: 318,
            fatEaten: 48,
            fatTarget: 70,
            streakCount: 12,
            healthScore: 85
        )
    }
}

// MARK: - Timeline Provider

struct HealthWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> HealthWidgetEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HealthWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.snapshot)
            return
        }
        completion(loadCurrentEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthWidgetEntry>) -> Void) {
        let entry = loadCurrentEntry()
        
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadCurrentEntry() -> HealthWidgetEntry {
        let container = ModelContainer.shared()
        let context = ModelContext(container)
        
        // Fetch user profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profile = try? context.fetch(profileDescriptor).first
        
        // Fetch today's logs
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let logDescriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { $0.date == today }
        )
        let todayLogs = (try? context.fetch(logDescriptor)) ?? []
        
        // Calculate totals
        let caloriesEaten = todayLogs.reduce(0) { $0 + $1.estimatedCalories }
        let proteinEaten = todayLogs.reduce(0.0) { $0 + $1.proteinG }
        let carbsEaten = todayLogs.reduce(0.0) { $0 + $1.carbsG }
        let fatEaten = todayLogs.reduce(0.0) { $0 + $1.fatG }
        
        return HealthWidgetEntry(
            date: Date(),
            caloriesEaten: caloriesEaten,
            caloriesTarget: profile?.calculatedDailyCalories ?? 2000,
            proteinEaten: proteinEaten,
            proteinTarget: Double(profile?.calculatedDailyProtein ?? 100),
            carbsEaten: carbsEaten,
            carbsTarget: Double(profile?.calculatedDailyCarbs ?? 250),
            fatEaten: fatEaten,
            fatTarget: Double(profile?.calculatedDailyFats ?? 65),
            streakCount: profile?.streakCount ?? 0,
            healthScore: profile?.healthScore ?? 0
        )
    }
}
