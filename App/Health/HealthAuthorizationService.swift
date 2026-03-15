import Foundation
import HealthKit

@MainActor
final class HealthAuthorizationService: ObservableObject {
    let manager: HealthKitManager
    
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    init(manager: HealthKitManager = .shared) {
        self.manager = manager
    }
    
    var requiredReadTypes: Set<HKObjectType> {
        return [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType()
        ]
    }
    
    var requiredWriteTypes: Set<HKSampleType> {
        return [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!
        ]
    }
    
    func requestBasicAuthorization() async throws {
        guard let store = manager.healthStore else { throw HealthError.notAvailable }
        
        do {
            try await store.requestAuthorization(toShare: requiredWriteTypes, read: requiredReadTypes)
            // Note: HKHealthStore doesn't return a bool for async requestAuthorization in older OS, but it throws if it fails.
            // In iOS 15+ it doesn't return anything. 
            checkAuthorizationStatus()
        } catch {
            throw HealthError.queryFailed(error.localizedDescription)
        }
    }
    
    func checkAuthorizationStatus() {
        guard let store = manager.healthStore, let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        authorizationStatus = store.authorizationStatus(for: stepType)
    }
}
