import Foundation

// MARK: - Generation Config

struct GenerationConfig {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
    let repetitionPenalty: Double?
    let stopTokens: [String]?
    let timeoutSeconds: TimeInterval
    
    static let `default` = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
        topP: 0.9,
        repetitionPenalty: nil,
        stopTokens: nil,
        timeoutSeconds: 30
    )
}

// MARK: - Generation Presets

enum GenerationPreset {
    case fastChat
    case nutritionSummary
    case foodAnalysis
    case medicalDocQA
    case reportSimplify
    case healthCaution
    case mealRecommendation
    
    var config: GenerationConfig {
        switch self {
        case .fastChat:
            return GenerationConfig(
                temperature: 0.8,
                maxOutputTokens: 512,
                topP: 0.9,
                repetitionPenalty: 1.1,
                stopTokens: nil,
                timeoutSeconds: 15
            )
        case .nutritionSummary:
            return GenerationConfig(
                temperature: 0.3,
                maxOutputTokens: 256,
                topP: 0.85,
                repetitionPenalty: nil,
                stopTokens: nil,
                timeoutSeconds: 20
            )
        case .foodAnalysis:
            return GenerationConfig(
                temperature: 0.2,
                maxOutputTokens: 512,
                topP: 0.8,
                repetitionPenalty: nil,
                stopTokens: nil,
                timeoutSeconds: 25
            )
        case .medicalDocQA:
            return GenerationConfig(
                temperature: 0.3,
                maxOutputTokens: 1024,
                topP: 0.85,
                repetitionPenalty: 1.05,
                stopTokens: nil,
                timeoutSeconds: 45
            )
        case .reportSimplify:
            return GenerationConfig(
                temperature: 0.5,
                maxOutputTokens: 768,
                topP: 0.9,
                repetitionPenalty: nil,
                stopTokens: nil,
                timeoutSeconds: 30
            )
        case .healthCaution:
            return GenerationConfig(
                temperature: 0.1,
                maxOutputTokens: 256,
                topP: 0.85,
                repetitionPenalty: nil,
                stopTokens: nil,
                timeoutSeconds: 10
            )
        case .mealRecommendation:
            return GenerationConfig(
                temperature: 0.6,
                maxOutputTokens: 1024,
                topP: 0.9,
                repetitionPenalty: 1.1,
                stopTokens: nil,
                timeoutSeconds: 30
            )
        }
    }
}
