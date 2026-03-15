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
        
        // Using modern HKSampleQueryDescriptor
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
}
