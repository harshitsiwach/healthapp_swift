import Foundation
import HealthKit

@MainActor
final class HealthSyncService: ObservableObject {
    let manager: HealthKitManager
    
    init(manager: HealthKitManager = .shared) {
        self.manager = manager
    }
    
    func saveNutrition(calories: Double, carbs: Double, protein: Double, fat: Double, date: Date = Date(), name: String) async throws {
        guard let store = manager.healthStore else { throw HealthError.notAvailable }
        
        let metadata: [String: Any] = [
            HKMetadataKeyFoodType: name,
            "HealthApp_Sync": true
        ]
        
        var samples: [HKQuantitySample] = []
        
        if let energyType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let quantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
            samples.append(HKQuantitySample(type: energyType, quantity: quantity, start: date, end: date, metadata: metadata))
        }
        
        if let carbsType = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let quantity = HKQuantity(unit: HKUnit.gram(), doubleValue: carbs)
            samples.append(HKQuantitySample(type: carbsType, quantity: quantity, start: date, end: date, metadata: metadata))
        }
        
        if let proteinType = HKObjectType.quantityType(forIdentifier: .dietaryProtein) {
            let quantity = HKQuantity(unit: HKUnit.gram(), doubleValue: protein)
            samples.append(HKQuantitySample(type: proteinType, quantity: quantity, start: date, end: date, metadata: metadata))
        }
        
        if let fatType = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal) {
            let quantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fat)
            samples.append(HKQuantitySample(type: fatType, quantity: quantity, start: date, end: date, metadata: metadata))
        }
        
        try await store.save(samples)
    }
}
