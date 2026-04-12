import Foundation
import WeatherKit
import CoreLocation

// MARK: - Weather Hydration Service

@MainActor
final class WeatherHydrationService: ObservableObject {
    
    static let shared = WeatherHydrationService()
    private let weatherService = WeatherService()
    
    @Published var currentTemperature: Double?
    @Published var humidity: Double?
    @Published var hydrationMultiplier: Double = 1.0
    @Published var weatherDescription: String = ""
    
    private init() {}
    
    // MARK: - Fetch Weather
    
    func fetchWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
            
            let temp = weather.currentWeather.temperature.value
            let hum = weather.currentWeather.humidity * 100
            let condition = weather.currentWeather.condition
            
            currentTemperature = temp
            humidity = hum
            weatherDescription = condition.description
            
            // Calculate hydration multiplier
            hydrationMultiplier = calculateHydrationMultiplier(
                temperature: temp,
                humidity: hum,
                condition: condition
            )
        } catch {
            // Silently fail — weather is optional
            hydrationMultiplier = 1.0
        }
    }
    
    // MARK: - Calculate Hydration Needs
    
    /// Returns a multiplier for base water intake based on weather
    private func calculateHydrationMultiplier(
        temperature: Double,
        humidity: Double,
        condition: WeatherCondition
    ) -> Double {
        var multiplier = 1.0
        
        // Temperature adjustments (Celsius)
        if temperature > 40 {
            multiplier = 1.6  // Extreme heat (common in Indian summers)
        } else if temperature > 35 {
            multiplier = 1.4
        } else if temperature > 30 {
            multiplier = 1.25
        } else if temperature > 25 {
            multiplier = 1.1
        } else if temperature < 10 {
            multiplier = 0.9
        }
        
        // Humidity adjustments
        if humidity > 80 {
            multiplier *= 1.15  // High humidity = more sweating
        } else if humidity < 30 {
            multiplier *= 1.1   // Dry air = faster dehydration
        }
        
        // Condition adjustments
        switch condition {
        case .hot:
            multiplier *= 1.15
        case .blizzard, .snow:
            multiplier *= 0.9
        default:
            break
        }
        
        return min(multiplier, 2.0) // Cap at 2x
    }
    
    // MARK: - Get Daily Water Recommendation
    
    func getDailyWaterRecommendation(baseLiters: Double = 2.5) -> WaterRecommendation {
        let adjustedLiters = baseLiters * hydrationMultiplier
        let glasses = Int(adjustedLiters / 0.25) // 250ml glasses
        
        var tips: [String] = []
        
        if let temp = currentTemperature {
            if temp > 35 {
                tips.append("It's \(Int(temp))°C outside — drink water even if you're not thirsty.")
                tips.append("Add a pinch of salt and lemon for natural electrolytes.")
            } else if temp > 30 {
                tips.append("Warm weather — keep a water bottle with you.")
            }
        }
        
        if humidity ?? 0 > 70 {
            tips.append("High humidity means you're sweating more than you realize.")
        }
        
        if tips.isEmpty {
            tips.append("Aim for \(glasses) glasses of water today.")
        }
        
        return WaterRecommendation(
            liters: adjustedLiters,
            glasses: glasses,
            multiplier: hydrationMultiplier,
            tips: tips,
            temperature: currentTemperature,
            humidity: humidity,
            condition: weatherDescription
        )
    }
}

// MARK: - Water Recommendation Model

struct WaterRecommendation {
    let liters: Double
    let glasses: Int
    let multiplier: Double
    let tips: [String]
    let temperature: Double?
    let humidity: Double?
    let condition: String
    
    var formattedLiters: String {
        String(format: "%.1f", liters)
    }
    
    var weatherContext: String {
        guard let temp = temperature else { return "" }
        return "\(Int(temp))°C · \(condition)"
    }
}
