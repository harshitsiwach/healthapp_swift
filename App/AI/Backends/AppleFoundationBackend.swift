import Foundation

// MARK: - Apple Foundation Backend

final class AppleFoundationBackend: AIBackend {
    let id: String = "apple_foundation"
    let displayName: String = "Apple Intelligence"
    let supportsVision: Bool = false
    let supportsToolCalling: Bool = true
    let maxContextWindow: Int? = 4096
    
    private var isAvailable: Bool = false
    
    // MARK: - Capability Check
    
    struct AppleModelCapability {
        let isSupportedOS: Bool
        let isAppleIntelligenceCapable: Bool
        let isAppleIntelligenceEnabled: Bool
        let canUseFoundationModels: Bool
    }
    
    func checkCapability() -> AppleModelCapability {
        // Runtime capability detection
        let isSupportedOS: Bool
        if #available(iOS 26, *) {
            isSupportedOS = true
        } else {
            isSupportedOS = false
        }
        
        // In a real implementation, check for Apple Intelligence entitlement
        // For now, enable it if on supported OS for testing
        return AppleModelCapability(
            isSupportedOS: isSupportedOS,
            isAppleIntelligenceCapable: isSupportedOS,
            isAppleIntelligenceEnabled: isSupportedOS,
            canUseFoundationModels: isSupportedOS
        )
    }
    
    // MARK: - AIBackend Conformance
    
    func prepare() async throws {
        let capability = checkCapability()
        guard capability.canUseFoundationModels else {
            throw AIError.noBackendAvailable
        }
        isAvailable = true
    }

        func warmup() async {
        // Apple models warm up automatically
        }

        func generate(_ request: AIRequest) async throws -> AIResponse {
        guard isAvailable else {
            throw AIError.noBackendAvailable
        }

        // Mocking Apple Intelligence response
        var responseText = ""
        switch request.task {
        case .mealRecommendation:
            responseText = """
            [
                {
                    "name": "Moong Dal Khichdi",
                    "calories": 320,
                    "protein": 12.0,
                    "carbs": 55.0,
                    "fat": 8.0,
                    "description": "A light and easily digestible one-pot meal made with rice and yellow moong dal, tempered with ghee and cumin."
                },
                {
                    "name": "Grilled Paneer Salad",
                    "calories": 280,
                    "protein": 18.0,
                    "carbs": 10.0,
                    "fat": 18.0,
                    "description": "Cubes of paneer grilled with Indian spices and tossed with fresh cucumber, tomatoes, and a lemon dressing."
                },
                {
                    "name": "Oats Upma",
                    "calories": 250,
                    "protein": 9.0,
                    "carbs": 40.0,
                    "fat": 7.0,
                    "description": "A savory South Indian breakfast made with roasted oats, mixed vegetables, and a tempering of mustard seeds and curry leaves."
                },
                {
                    "name": "Chicken Tikka (Dry)",
                    "calories": 350,
                    "protein": 45.0,
                    "carbs": 5.0,
                    "fat": 15.0,
                    "description": "Lean chicken pieces marinated in yogurt and spices, grilled to perfection. High in protein."
                },
                {
                    "name": "Sprouted Moong Salad",
                    "calories": 210,
                    "protein": 14.0,
                    "carbs": 35.0,
                    "fat": 2.0,
                    "description": "Nutritious sprouted green moong beans mixed with onions, green chilies, and tangy chaat masala."
                }
            ]
            """
        default:
            responseText = "Apple Intelligence: I'm ready to help with your health and nutrition."
        }

        return AIResponse(
            text: responseText,
            attribution: AIBackendAttribution(
                backendID: .appleFoundation,
                modelVersion: "apple-fm-1.0",
                isOnDevice: true
            ),
            metadata: AIResponseMetadata(
                timeToFirstTokenMs: 50,
                totalLatencyMs: 200,
                tokensIn: request.userPrompt.count / 4,
                tokensOut: responseText.count / 4,
                wasCancelled: false,
                failureReason: nil
            )
        )
        }
    
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard isAvailable else {
                    continuation.finish(throwing: AIError.noBackendAvailable)
                    return
                }
                
                let stubResponse: String
                switch request.task {
                case .chat:
                    stubResponse = "Using Apple Intelligence, I'm analyzing your health data right here on your device. Let me know if you need any meal ideas or help understanding your progress."
                default:
                    stubResponse = "Processing request on-device..."
                }
                
                let words = stubResponse.split(separator: " ")
                for (index, word) in words.enumerated() {
                    let isLast = index == words.count - 1
                    continuation.yield(AITokenEvent(
                        token: String(word) + (isLast ? "" : " "),
                        isComplete: isLast,
                        tokenIndex: index,
                        elapsedMs: Double(index) * 30
                    ))
                    try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
                }
                continuation.finish()
            }
        }
    }
    
    func cancelCurrentGeneration() {
        // Cancel any in-flight Foundation Models request
    }
    
    func healthCheck() async -> AIBackendHealth {
        let capability = checkCapability()
        if capability.canUseFoundationModels {
            return .healthy
        }
        return .unavailable(reason: "Apple Intelligence not available on this device")
    }
}
