import Foundation

struct DailyHealthSummary {
    let steps: Double
    let activeEnergyKJ: Double // wait, we fetched kcal earlier
    let activeEnergyKcal: Double
    let latestHeartRate: Double?
    let lastNightSleepHours: Double?
    let latestWeightKg: Double?
    
    var aiContextString: String {
        var context = "HealthKit Data Context:\n"
        context += "- Today's Steps: \(Int(steps))\n"
        if activeEnergyKcal > 0 {
            context += "- Active Calories Burned: \(Int(activeEnergyKcal)) kcal\n"
        }
        if let hr = latestHeartRate {
            context += "- Latest Heart Rate: \(Int(hr)) bpm\n"
        }
        if let sleep = lastNightSleepHours {
            context += String(format: "- Last Night's Sleep: %.1f hours\n", sleep)
        }
        if let weight = latestWeightKg {
             context += String(format: "- Latest Logged Weight: %.1f kg\n", weight)
        }
        return context
    }
}

@MainActor
final class HealthInsightsService: ObservableObject {
    private let repository: HealthDataRepository
    
    @Published var lastSummary: DailyHealthSummary?
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?
    
    init(repository: HealthDataRepository? = nil) {
        self.repository = repository ?? HealthDataRepository()
    }
    
    func refreshSummary() async {
        isRefreshing = true
        errorMessage = nil
        
        do {
            async let stepsTask = repository.fetchTodaySteps()
            async let energyTask = repository.fetchTodayActiveEnergy()
            async let hrTask = repository.fetchRecentHeartRate()
            async let sleepTask = repository.fetchLastNightSleepDuration()
            async let weightTask = repository.fetchLatestWeight()
            
            // Wait for all to complete. (If one fails, we might want to catch individually in production to not fail the whole batch, but this is fine for now).
            let (steps, energy, hr, sleep, weight) = try await (stepsTask, energyTask, hrTask, sleepTask, weightTask)
            
            lastSummary = DailyHealthSummary(
                steps: steps,
                activeEnergyKJ: energy * 4.184,
                activeEnergyKcal: energy,
                latestHeartRate: hr,
                lastNightSleepHours: sleep,
                latestWeightKg: weight
            )
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to fetch health insights: \(error)")
        }
        
        isRefreshing = false
    }
}
