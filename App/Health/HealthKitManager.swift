import Foundation
import HealthKit

enum HealthError: LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(String)
    case invalidData
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .notAvailable: return "HealthKit is not available on this device."
        case .notAuthorized: return "Missing permissions to access Apple Health."
        case .queryFailed(let details): return "Failed to read Health data: \(details)"
        case .invalidData: return "Received invalid data from HealthKit."
        case .userCancelled: return "User cancelled the operation."
        }
    }
}

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }
    
    var isAvailable: Bool {
        return healthStore != nil
    }
}
