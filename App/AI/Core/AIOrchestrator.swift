import Foundation

// MARK: - Orchestrator Protocol

protocol AIOrchestrating {
    func activeBackend(for task: AITask) async throws -> any AIBackend
    func generate(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error>
}

// MARK: - AI Orchestrator

@MainActor
final class AIOrchestrator: ObservableObject, AIOrchestrating {
    
    @Published var currentBackendID: AIBackendID = .gemmaLocal
    @Published var isGenerating: Bool = false
    @Published var activeBackendOverride: AIBackendID? = nil
    
    private let appleBackend: AppleFoundationBackend
    private let gemmaBackend: GemmaLocalBackend
    private let safetyFilter: HealthSafetyFilter
    private let telemetry: AITelemetry
    
    init(
        appleBackend: AppleFoundationBackend? = nil,
        gemmaBackend: GemmaLocalBackend? = nil,
        safetyFilter: HealthSafetyFilter? = nil,
        telemetry: AITelemetry? = nil
    ) {
        self.appleBackend = appleBackend ?? AppleFoundationBackend()
        self.gemmaBackend = gemmaBackend ?? GemmaLocalBackend()
        self.safetyFilter = safetyFilter ?? HealthSafetyFilter()
        self.telemetry = telemetry ?? AITelemetry()
    }
    
    // MARK: - Backend Selection
    
    nonisolated func activeBackend(for task: AITask) async throws -> any AIBackend {
        // Obey override if set
        if let override = await MainActor.run(body: { activeBackendOverride }) {
            switch override {
            case .appleFoundation:
                if case .degraded = await appleBackend.healthCheck() {
                    try? await appleBackend.prepare()
                }
                return appleBackend
            case .gemmaLocal:
                if case .degraded = await gemmaBackend.healthCheck() {
                    try? await gemmaBackend.prepare()
                }
                return gemmaBackend
            }
        }
        
        // Priority 1: Gemma local
        let gemmaHealth = await gemmaBackend.healthCheck()
        switch gemmaHealth {
        case .healthy:
            return gemmaBackend
        case .degraded:
            try? await gemmaBackend.prepare()
            return gemmaBackend
        default:
            break
        }
        
        // Priority 2: Apple Foundation fallback
        let appleHealth = await appleBackend.healthCheck()
        switch appleHealth {
        case .healthy:
            return appleBackend
        case .degraded, .unavailable:
            try? await appleBackend.prepare()
            let newHealth = await appleBackend.healthCheck()
            if case .healthy = newHealth {
                return appleBackend
            }
        }
        
        throw AIError.noBackendAvailable
    }
    
    // MARK: - Generate
    
    nonisolated func generate(_ request: AIRequest) async throws -> AIResponse {
        // Pre-generation safety check
        let safetyResult = await safetyFilter.checkInput(request.userPrompt, task: request.task)
        if case .blocked(let category) = safetyResult {
            throw AIError.safetyTriggered(category: category)
        }
        
        let backend = try await activeBackend(for: request.task)
        
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
                let backend = try await activeBackend(for: request.task)
                
                do {
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