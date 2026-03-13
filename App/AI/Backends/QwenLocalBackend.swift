import Foundation

// MARK: - Qwen Local Backend

@MainActor
final class QwenLocalBackend: AIBackend {
    let id: String = "qwen_local"
    let displayName: String = "Qwen 3.5 0.8B (Local)"
    let supportsVision: Bool = false
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
        
        // Stub: In production, use llama.cpp or MLX runtime
        return AIResponse(
            text: "[Qwen local model not yet configured. Please install a model in Settings.]",
            attribution: AIBackendAttribution(
                backendID: .qwenLocal,
                modelVersion: "qwen3.5-0.8b-q4",
                isOnDevice: true
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
                
                // Stub: In production, stream from llama.cpp/MLX
                let stubResponse = "Local model inference is not yet configured."
                for (index, word) in stubResponse.split(separator: " ").enumerated() {
                    let isLast = index == stubResponse.split(separator: " ").count - 1
                    continuation.yield(AITokenEvent(
                        token: String(word) + " ",
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
            return .unavailable(reason: "No model installed")
        }
        
        if isReady {
            return .healthy
        }
        
        return .degraded(reason: "Model installed but not initialized")
    }
    
    func unloadModel() {
        isReady = false
        // In production: Free runtime memory
    }
}
