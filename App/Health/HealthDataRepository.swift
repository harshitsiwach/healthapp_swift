import Foundation
import HealthKit

@MainActor
final class HealthDataRepository: ObservableObject {
    let manager: HealthKitManager
    
    init(manager: HealthKitManager = .shared) {
        self.manager = manager
    }
    
    // MARK: - Generic Fetch
    
    private func fetchSamples(for type: HKSampleType, predicate: NSPredicate, limit: Int = HKObjectQueryNoLimit) async throws -> [HKSample] {
        guard let store = manager.healthStore else { throw HealthError.notAvailable }
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.sample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: limit
        )
        
        return try await descriptor.result(for: store)
    }
    
    // MARK: - Daily Steps
    
    func fetchTodaySteps() async throws -> Double {
        guard let store = manager.healthStore,
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthError.notAvailable
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: stepType, predicate: predicate)
        
        let query = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: .cumulativeSum)
        if let result = try await query.result(for: store) {
            return result.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0.0
        }
        return 0.0
    }
    
    // MARK: - Active Energy
    
    func fetchTodayActiveEnergy() async throws -> Double {
        guard let store = manager.healthStore,
              let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthError.notAvailable
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: energyType, predicate: predicate)
        
        let query = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: .cumulativeSum)
        if let result = try await query.result(for: store) {
            return result.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0.0
        }
        return 0.0
    }
    
    // MARK: - Today's Workouts
    
    func fetchTodayWorkouts() async throws -> [WorkoutSummary] {
        guard let store = manager.healthStore else { throw HealthError.notAvailable }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let samples = try await fetchSamples(for: HKObjectType.workoutType(), predicate: predicate, limit: 20)
        
        return samples.compactMap { sample -> WorkoutSummary? in
            guard let workout = sample as? HKWorkout else { return nil }
            
            let duration = workout.duration / 60.0 // minutes
            let calories = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            let distance = workout.totalDistance?.doubleValue(for: HKUnit.meterUnit(with: .kilo)) ?? 0
            
            return WorkoutSummary(
                type: workout.workoutActivityType.displayName,
                durationMinutes: duration,
                caloriesBurned: calories,
                distanceKm: distance,
                startDate: workout.startDate,
                endDate: workout.endDate
            )
        }
    }
    
    // MARK: - Adjusted Daily Target
    
    /// Calculates adjusted daily calorie target based on actual activity
    func calculateAdjustedTarget(baseTarget: Int) async -> AdjustedCalorieTarget {
        do {
            let activeEnergy = try await fetchTodayActiveEnergy()
            let workouts = try await fetchTodayWorkouts()
            let steps = try await fetchTodaySteps()
            
            // Bonus calories from exercise (capped at reasonable amount)
            let exerciseBonus = min(activeEnergy, Double(baseTarget) * 0.3) // Max 30% bonus
            
            // Step bonus (roughly 1 extra cal per 20 steps above 5000)
            let stepBonus = max(0, (steps - 5000) / 20)
            
            let totalAdjustment = Int(exerciseBonus + stepBonus)
            let adjustedTarget = baseTarget + totalAdjustment
            
            return AdjustedCalorieTarget(
                baseTarget: baseTarget,
                activeEnergy: activeEnergy,
                stepBonus: stepBonus,
                workoutCalories: workouts.reduce(0) { $0 + $1.caloriesBurned },
                adjustedTarget: adjustedTarget,
                workouts: workouts,
                steps: steps
            )
        } catch {
            return AdjustedCalorieTarget(
                baseTarget: baseTarget,
                activeEnergy: 0,
                stepBonus: 0,
                workoutCalories: 0,
                adjustedTarget: baseTarget,
                workouts: [],
                steps: 0
            )
        }
    }
    
    // MARK: - Recent Heart Rate
    
    func fetchRecentHeartRate() async throws -> Double? {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { throw HealthError.notAvailable }
        
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictEndDate)
        
        let samples = try await fetchSamples(for: hrType, predicate: predicate, limit: 1)
        if let lastSample = samples.first as? HKQuantitySample {
            return lastSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        }
        return nil
    }
    
    // MARK: - Blood Glucose (for diabetic users — huge in India)
    
    func fetchRecentBloodGlucose() async throws -> Double? {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { throw HealthError.notAvailable }
        
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictEndDate)
        
        let samples = try await fetchSamples(for: glucoseType, predicate: predicate, limit: 1)
        if let lastSample = samples.first as? HKQuantitySample {
            return lastSample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
        }
        return nil
    }
    
    // MARK: - Sleep
    
    func fetchLastNightSleepDuration() async throws -> Double? {
        guard let store = manager.healthStore,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { throw HealthError.notAvailable }
        
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictEndDate)
        let samples = try await fetchSamples(for: sleepType, predicate: predicate, limit: 50)
        
        var totalSleepInCoreOrDeepSeconds: TimeInterval = 0
        
        for case let sample as HKCategorySample in samples {
            if sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
               sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
               sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
               sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                
                totalSleepInCoreOrDeepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
            }
        }
        
        return totalSleepInCoreOrDeepSeconds > 0 ? (totalSleepInCoreOrDeepSeconds / 3600.0) : nil
    }
    
    // MARK: - Body Mass
    
    func fetchLatestWeight() async throws -> Double? {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { throw HealthError.notAvailable }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let samples = try await fetchSamples(for: weightType, predicate: predicate, limit: 1)
        
        if let lastSample = samples.first as? HKQuantitySample {
            return lastSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
        }
        return nil
    }
    
    // MARK: - Write Nutrition to HealthKit
    
    func writeMealToHealthKit(foodName: String, calories: Int, protein: Double, carbs: Double, fat: Double) async throws {
        guard let store = manager.healthStore else { throw HealthError.notAvailable }
        
        let now = Date()
        
        let calorieType = HKQuantityType(.dietaryEnergyConsumed)
        let proteinType = HKQuantityType(.dietaryProtein)
        let carbsType = HKQuantityType(.dietaryCarbohydrates)
        let fatType = HKQuantityType(.dietaryFatTotal)
        
        let samples: [HKQuantitySample] = [
            HKQuantitySample(type: calorieType, quantity: HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories)), start: now, end: now),
            HKQuantitySample(type: proteinType, quantity: HKQuantity(unit: .gram(), doubleValue: protein), start: now, end: now),
            HKQuantitySample(type: carbsType, quantity: HKQuantity(unit: .gram(), doubleValue: carbs), start: now, end: now),
            HKQuantitySample(type: fatType, quantity: HKQuantity(unit: .gram(), doubleValue: fat), start: now, end: now)
        ]
        
        try await store.save(samples)
    }
}

// MARK: - Supporting Types

struct WorkoutSummary: Identifiable {
    let id = UUID()
    let type: String
    let durationMinutes: Double
    let caloriesBurned: Double
    let distanceKm: Double
    let startDate: Date
    let endDate: Date
}

struct AdjustedCalorieTarget {
    let baseTarget: Int
    let activeEnergy: Double
    let stepBonus: Double
    let workoutCalories: Double
    let adjustedTarget: Int
    let workouts: [WorkoutSummary]
    let steps: Double
    
    var hasAdjustment: Bool {
        return adjustedTarget > baseTarget
    }
    
    var adjustmentText: String {
        let diff = adjustedTarget - baseTarget
        if diff > 0 {
            return "+\(diff) kcal from activity"
        }
        return ""
    }
}

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .dance: return "Dance"
        case .hiking: return "Hiking"
        case .americanFootball: return "Football"
        default: return "Workout"
        }
    }
}
