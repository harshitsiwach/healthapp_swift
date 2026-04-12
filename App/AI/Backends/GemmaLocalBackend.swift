import Foundation

// MARK: - Gemma Local Backend

@MainActor
final class GemmaLocalBackend: AIBackend {
    let id: String = "gemma_local"
    let displayName: String = "Gemma 4 (On-Device)"
    let supportsVision: Bool = true
    let supportsToolCalling: Bool = false
    let maxContextWindow: Int? = 8192
    
    private let modelStore: ModelStore
    private var isReady: Bool = false
    
    init(modelStore: ModelStore? = nil) {
        self.modelStore = modelStore ?? ModelStore()
    }
    
    // MARK: - AIBackend Conformance
    
    func prepare() async throws {
        guard let manifest = modelStore.installedManifest else {
            throw AIError.modelMissing
        }
        
        guard manifest.id.contains("gemma") else {
            throw AIError.modelMissing
        }
        
        // Verify integrity
        let validator = ModelIntegrityValidator()
        let isValid = await validator.validate(manifest: manifest)
        guard isValid else {
            throw AIError.modelChecksumFailed
        }
        
        // In production: Initialize llama.cpp/MLX runtime here
        // let runtime = try LlamaRuntime(modelPath: manifest.localPath)
        // self.runtime = runtime
        
        isReady = true
    }
    
    func warmup() async {
        guard isReady else { return }
        // In production: Run a short warmup inference
        // try? await runtime?.generate("Hello", maxTokens: 1)
    }
    
    func generate(_ request: AIRequest) async throws -> AIResponse {
        guard isReady else {
            throw AIError.modelMissing
        }
        
        // Mocking Local Gemma 4 response
        var responseText = ""
        switch request.task {
        case .mealRecommendation:
            responseText = """
            [
                {
                    "name": "Poha with Sprouts",
                    "calories": 280,
                    "protein": 10.0,
                    "carbs": 45.0,
                    "fat": 6.0,
                    "description": "A traditional Maharashtrian breakfast made with flattened rice and enhanced with protein-rich sprouts."
                },
                {
                    "name": "Tofu Bhurji with 1 Roti",
                    "calories": 310,
                    "protein": 20.0,
                    "carbs": 30.0,
                    "fat": 12.0,
                    "description": "Scrambled tofu with onions, tomatoes, and Indian spices, served with a single whole wheat roti."
                },
                {
                    "name": "Masala Oats",
                    "calories": 220,
                    "protein": 8.0,
                    "carbs": 35.0,
                    "fat": 5.0,
                    "description": "Spicy oats cooked with peas, carrots, and beans. A quick and high-fiber meal."
                },
                {
                    "name": "Egg White Omelette with Veggies",
                    "calories": 180,
                    "protein": 22.0,
                    "carbs": 5.0,
                    "fat": 6.0,
                    "description": "Fluffy omelette made with egg whites and plenty of colorful bell peppers and spinach."
                },
                {
                    "name": "Dalia Khichdi",
                    "calories": 290,
                    "protein": 11.0,
                    "carbs": 50.0,
                    "fat": 5.0,
                    "description": "Broken wheat cooked with yellow moong dal and mild spices. A perfect light dinner."
                }
            ]
            """
        case .foodAnalysis:
            responseText = """
            {
                "food_name": "Mixed Vegetable Curry with Rice",
                "estimated_calories": 420,
                "protein_g": 12.0,
                "carbs_g": 65.0,
                "fat_g": 15.0
            }
            """
        default:
            responseText = "Gemma 4: I am running on your device and ready to help!"
        }
        
        return AIResponse(
            text: responseText,
            attribution: AIBackendAttribution(
                backendID: .gemmaLocal,
                modelVersion: "gemma-4-2b-q4",
                isOnDevice: true
            ),
            metadata: AIResponseMetadata(
                timeToFirstTokenMs: 150,
                totalLatencyMs: 800,
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
                guard isReady else {
                    continuation.finish(throwing: AIError.modelMissing)
                    return
                }
                
                // Mocking local streaming response
                let stubResponse: String
                switch request.task {
                case .chat:
                    stubResponse = "As Gemma 4 running locally on your device, I can help you track your nutrition, explain health reports, and suggest meals entirely offline. What would you like to focus on today?"
                default:
                    stubResponse = "Local model processing request..."
                }
                
                let words = stubResponse.split(separator: " ")
                for (index, word) in words.enumerated() {
                    let isLast = index == words.count - 1
                    continuation.yield(AITokenEvent(
                        token: String(word) + (isLast ? "" : " "),
                        isComplete: isLast,
                        tokenIndex: index,
                        elapsedMs: Double(index) * 50
                    ))
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                }
                continuation.finish()
            }
        }
    }
    
    func cancelCurrentGeneration() {
        // In production: Cancel llama.cpp/MLX inference
    }
    
    func healthCheck() async -> AIBackendHealth {
        guard modelStore.installedManifest != nil else {
            return .unavailable(reason: "No Gemma model installed")
        }
        
        guard modelStore.installedManifest?.id.contains("gemma") == true else {
            return .unavailable(reason: "No Gemma model installed")
        }
        
        if isReady {
            return .healthy
        }
        
        return .degraded(reason: "Gemma model installed but not initialized")
    }
    
    func unloadModel() {
        isReady = false
        // In production: Free runtime memory
    }
}