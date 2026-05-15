import Foundation
import HealthKit

actor HealthManager {
    static let shared = HealthManager()
    private let store = HKHealthStore()
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        var types: Set<HKObjectType> = []
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(hrType)
        }
        if let activeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeType)
        }
        if let basalType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(basalType)
        }
        if let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weightType)
        }
        
        do {
            try await store.requestAuthorization(toShare: [], read: types)
            return true
        } catch {
            print("Health auth error: \(error)")
            return false
        }
    }
    
    // MARK: - Fetch Steps (Quantity)
    
    func fetchTodaySteps() async -> Int? {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return nil }
        return await fetchTodayQuantitySum(for: type)
    }
    
    // MARK: - Fetch Sleep (Category)
    
    func fetchTodaySleep() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int.max, sortDescriptors: nil) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: nil); return
                }
                let hours = samples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 3600 }
                continuation.resume(returning: hours)
            }
            store.execute(query)
        }
    }
    
    // MARK: - Fetch Heart Rate (Quantity - Latest)
    
    func fetchLatestHeartRate() async -> Int? {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                    continuation.resume(returning: nil); return
                }
                let value = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                continuation.resume(returning: value)
            }
            self.store.execute(query)
        }
    }
    
    // MARK: - Fetch Weight (Quantity - Latest)
    
    func fetchLatestWeight() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                    continuation.resume(returning: nil); return
                }
                let value = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: value)
            }
            self.store.execute(query)
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchTodayQuantitySum(for type: HKQuantityType) async -> Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                guard let sum = stats?.sumQuantity(), error == nil else {
                    continuation.resume(returning: nil); return
                }
                let value = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: value)
            }
            self.store.execute(query)
        }
    }
}

// MARK: - Import Log (Simple struct, not CoreData)

struct HealthImportLog: Codable, Identifiable {
    let id: UUID
    let importDate: String
    let stepsImported: Int
    let sleepHoursImported: Double
    let heartRateImported: Int?
    let weightImported: Double?
    let source: String
    
    init(steps: Int, sleep: Double, heartRate: Int? = nil, weight: Double? = nil) {
        self.id = UUID()
        self.importDate = Date().formatted(date: .abbreviated, time: .omitted)
        self.stepsImported = steps
        self.sleepHoursImported = sleep
        self.heartRateImported = heartRate
        self.weightImported = weight
        self.source = "AppleHealth"
    }
}
