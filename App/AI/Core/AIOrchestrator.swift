import Foundation

// MARK: - Orchestrator Protocol

protocol AIOrchestrating {
    func activeBackend(for request: AIRequest) async throws -> any AIBackend
    func generate(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error>
}

// MARK: - AI Orchestrator

@MainActor
final class AIOrchestrator: ObservableObject, AIOrchestrating {
    static let shared = AIOrchestrator()
    
    @Published var currentBackendID: AIBackendID = .geminiRemote
    @Published var isGenerating: Bool = false
    @Published var activeBackendOverride: AIBackendID? = nil {
        didSet {
            if let newValue = activeBackendOverride {
                UserDefaults.standard.set(newValue.rawValue, forKey: "AIActiveBackendOverride")
            } else {
                UserDefaults.standard.removeObject(forKey: "AIActiveBackendOverride")
            }
        }
    }
    
    private let appleBackend: AppleFoundationBackend
    private let qwenBackend: QwenLocalBackend
    private let geminiService: GeminiService
    private let safetyFilter: HealthSafetyFilter
    private let telemetry: AITelemetry
    
    init(
        appleBackend: AppleFoundationBackend? = nil,
        qwenBackend: QwenLocalBackend? = nil,
        geminiService: GeminiService? = nil,
        safetyFilter: HealthSafetyFilter? = nil,
        telemetry: AITelemetry? = nil
    ) {
        self.appleBackend = appleBackend ?? AppleFoundationBackend()
        self.qwenBackend = qwenBackend ?? QwenLocalBackend()
        self.geminiService = geminiService ?? GeminiService()
        self.safetyFilter = safetyFilter ?? HealthSafetyFilter()
        self.telemetry = telemetry ?? AITelemetry()
        
        // Restore override from UserDefaults
        if let storedValue = UserDefaults.standard.string(forKey: "AIActiveBackendOverride"),
           let backend = AIBackendID(rawValue: storedValue) {
            self.activeBackendOverride = backend
        }
    }
    
    // MARK: - Backend Selection
    
    nonisolated func activeBackend(for request: AIRequest) async throws -> any AIBackend {
        let needsVision = !request.images.isEmpty
        
        // Obey override if set
        if let override = await MainActor.run(body: { activeBackendOverride }) {
            switch override {
            case .appleFoundation:
                if needsVision && !appleBackend.supportsVision {
                    throw AIError.unsupportedFeature("Apple Intelligence does not support image analysis yet.")
                }
                
                // Attempt to prepare if needed
                if case .degraded = await appleBackend.healthCheck() {
                    try? await appleBackend.prepare()
                }
                return appleBackend
                
            case .qwenLocal:
                if needsVision && !qwenBackend.supportsVision {
                    throw AIError.unsupportedFeature("This local model does not support image analysis yet.")
                }
                
                if case .degraded = await qwenBackend.healthCheck() {
                    try? await qwenBackend.prepare()
                }
                return qwenBackend
                
            case .geminiRemote:
                return geminiService
            }
        }
        
        // Priority 1: Qwen local
        if !needsVision || qwenBackend.supportsVision {
            let qwenHealth = await qwenBackend.healthCheck()
            switch qwenHealth {
            case .healthy:
                return qwenBackend
            case .degraded:
                // Attempt to prepare if it's just not initialized
                try? await qwenBackend.prepare()
                return qwenBackend
            default:
                break
            }
        }
        
        // Priority 2: Apple Foundation
        if !needsVision || appleBackend.supportsVision {
            let appleHealth = await appleBackend.healthCheck()
            switch appleHealth {
            case .healthy:
                return appleBackend
            case .degraded, .unavailable:
                // Attempt to prepare Apple backend
                try? await appleBackend.prepare()
                let newHealth = await appleBackend.healthCheck()
                if case .healthy = newHealth {
                    return appleBackend
                }
            }
        }
        
        // Priority 3: Gemini remote fallback
        return geminiService
    }
    
    // MARK: - Generate
    
    nonisolated func generate(_ request: AIRequest) async throws -> AIResponse {
        // Pre-generation safety check
        let safetyResult = await safetyFilter.checkInput(request.userPrompt, task: request.task)
        if case .blocked(let category) = safetyResult {
            throw AIError.safetyTriggered(category: category)
        }
        
        let backend = try await activeBackend(for: request)
        
        // Ensure backend is prepared
        try await backend.prepare()
        
        let startTime = Date()
        
        do {
            let response = try await backend.generate(request)
            
            // Post-generation safety check
            let outputSafety = await safetyFilter.checkOutput(response.text, task: request.task)
            if case .blocked(let category) = outputSafety {
                throw AIError.safetyTriggered(category: category)
            }
            
            // Log telemetry
            let duration = Date().timeIntervalSince(startTime) * 1000
            await telemetry.log(
                backendID: backend.id,
                task: request.task,
                latencyMs: duration,
                tokensIn: response.metadata.tokensIn,
                tokensOut: response.metadata.tokensOut,
                success: true
            )
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime) * 1000
            await telemetry.log(
                backendID: backend.id,
                task: request.task,
                latencyMs: duration,
                tokensIn: 0,
                tokensOut: 0,
                success: false,
                failureReason: error.localizedDescription
            )
            throw error
        }
    }
    
    // MARK: - Stream
    
    nonisolated func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let backend = try await activeBackend(for: request)
                    // Ensure backend is prepared
                    try await backend.prepare()
                    
                    let stream = backend.stream(request)
                    
                    for try await event in stream {
                        continuation.yield(event)
                        if event.isComplete {
                            continuation.finish()
                            return
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
