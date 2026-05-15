import Foundation
import Intents

// MARK: - Siri Shortcuts Manager

final class SiriShortcutsManager {
    
    static let shared = SiriShortcutsManager()
    
    private init() {}
    
    // MARK: - Donate Shortcuts
    
    /// Call this after a user logs a meal to teach Siri their patterns
    func donateMealLoggingShortcut() {
        let activity = NSUserActivity(activityType: "com.aihealthappoffline.logMeal")
        activity.title = "Log a meal"
        activity.userInfo = [:]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.isEligibleForPublicIndexing = false
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier("logMeal")
        activity.suggestedInvocationPhrase = "Log my meal"
        
        // This teaches Siri to suggest this shortcut
        // The view/controller should set this as its userActivity
    }
    
    /// Donate after logging a specific food for smarter suggestions
    func donateFoodLoggingShortcut(foodName: String) {
        let activity = NSUserActivity(activityType: "com.aihealthappoffline.logFood")
        activity.title = "Log \(foodName)"
        activity.userInfo = ["foodName": foodName]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.isEligibleForPublicIndexing = false
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier("logFood-\(foodName)")
        activity.suggestedInvocationPhrase = "Log \(foodName)"
    }
    
    /// Donate calories check shortcut
    func donateCaloriesCheckShortcut() {
        let activity = NSUserActivity(activityType: "com.aihealthappoffline.checkCalories")
        activity.title = "Check my calories"
        activity.userInfo = [:]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.isEligibleForPublicIndexing = false
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier("checkCalories")
        activity.suggestedInvocationPhrase = "Check my calories"
    }
    
    /// Donate water logging shortcut
    func donateWaterLoggingShortcut() {
        let activity = NSUserActivity(activityType: "com.aihealthappoffline.logWater")
        activity.title = "Log water"
        activity.userInfo = [:]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.isEligibleForPublicIndexing = false
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier("logWater")
        activity.suggestedInvocationPhrase = "Log water"
    }
    
    // MARK: - Handle Shortcuts
    
    /// Returns the navigation target based on the user activity
    static func handleUserActivity(_ userActivity: NSUserActivity) -> ShortcutAction? {
        switch userActivity.activityType {
        case "com.aihealthappoffline.logMeal":
            return .logMeal
        case "com.aihealthappoffline.logFood":
            let foodName = userActivity.userInfo?["foodName"] as? String
            return .logFood(name: foodName)
        case "com.aihealthappoffline.checkCalories":
            return .checkCalories
        case "com.aihealthappoffline.logWater":
            return .logWater
        default:
            return nil
        }
    }
}

// MARK: - Shortcut Actions

enum ShortcutAction {
    case logMeal
    case logFood(name: String?)
    case checkCalories
    case logWater
}
