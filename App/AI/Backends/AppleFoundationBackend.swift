import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Apple Foundation Backend

final class AppleFoundationBackend: AIBackend {
    let id: String = "apple_foundation"
    let displayName: String = "Apple Intelligence"
    let supportsVision: Bool = false
    let supportsToolCalling: Bool = true
    let maxContextWindow: Int? = 4096
    
    private var isAvailable: Bool = false
    
    #if canImport(FoundationModels)
    private var sessionAny: Any?
    
    @available(iOS 26, *)
    private var session: LanguageModelSession? {
        get { sessionAny as? LanguageModelSession }
        set { sessionAny = newValue }
    }
    #endif
    
    // MARK: - Capability Check
    
    struct AppleModelCapability {
        let isSupportedOS: Bool
        let isAppleIntelligenceCapable: Bool
        let isAppleIntelligenceEnabled: Bool
        let canUseFoundationModels: Bool
    }
    
    func checkCapability() -> AppleModelCapability {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return AppleModelCapability(isSupportedOS: true, isAppleIntelligenceCapable: true, isAppleIntelligenceEnabled: true, canUseFoundationModels: true)
            case .unavailable(.appleIntelligenceNotEnabled):
                return AppleModelCapability(isSupportedOS: true, isAppleIntelligenceCapable: true, isAppleIntelligenceEnabled: false, canUseFoundationModels: false)
            default:
                return AppleModelCapability(isSupportedOS: true, isAppleIntelligenceCapable: true, isAppleIntelligenceEnabled: true, canUseFoundationModels: false)
            }
        }
        #endif
        return AppleModelCapability(isSupportedOS: false, isAppleIntelligenceCapable: false, isAppleIntelligenceEnabled: false, canUseFoundationModels: false)
    }
    
    // MARK: - AIBackend Conformance
    
    func prepare() async throws {
        let capability = checkCapability()
        guard capability.canUseFoundationModels else {
            throw AIError.noBackendAvailable
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            self.session = LanguageModelSession()
            isAvailable = true
        } else {
            throw AIError.noBackendAvailable
        }
        #else
        throw AIError.noBackendAvailable
        #endif
    }
    
    func warmup() async {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            guard let session = session else { return }
            // Not awaiting since warmup shouldn't block initialization significantly
            Task {
                try? await session.prewarm()
            }
        }
        #endif
    }
    
    func generate(_ request: AIRequest) async throws -> AIResponse {
        guard isAvailable else {
            throw AIError.noBackendAvailable
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            guard let session = session else { throw AIError.noBackendAvailable }
            
            let startTime = Date()
            
            // Build full prompt including system instructions and context
            let fullPrompt = buildFullPrompt(for: request)
            
            let response = try await session.respond(to: fullPrompt)
            let responseString = response.content
            
            let endTime = Date()
            let latencyMs = Double(endTime.timeIntervalSince(startTime) * 1000)
            
            return AIResponse(
                text: responseString,
                attribution: AIBackendAttribution(
                    backendID: .appleFoundation,
                    modelVersion: "SystemLanguageModel",
                    isOnDevice: true
                ),
                metadata: AIResponseMetadata(
                    timeToFirstTokenMs: latencyMs * 0.2, // Rough estimate
                    totalLatencyMs: latencyMs,
                    tokensIn: 0,
                    tokensOut: 0,
                    wasCancelled: false,
                    failureReason: nil
                )
            )
        }
        #endif
        
        throw AIError.noBackendAvailable
    }
    
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard isAvailable else {
                    continuation.finish(throwing: AIError.noBackendAvailable)
                    return
                }
                
                #if canImport(FoundationModels)
                if #available(iOS 26, *) {
                    guard let session = session else {
                        continuation.finish(throwing: AIError.noBackendAvailable)
                        return
                    }
                    
                    let fullPrompt = buildFullPrompt(for: request)
                    let startTime = Date()
                    
                    do {
                        let stream = session.streamResponse(to: fullPrompt)
                        var index = 0
                        var lastContent = ""
                        
                        for try await snapshot in stream {
                            let fullContent = snapshot.content
                            let delta = String(fullContent.suffix(fullContent.count - lastContent.count))
                            
                            if !delta.isEmpty {
                                continuation.yield(AITokenEvent(
                                    token: delta,
                                    isComplete: false,
                                    tokenIndex: index,
                                    elapsedMs: Date().timeIntervalSince(startTime) * 1000
                                ))
                                index += 1
                                lastContent = fullContent
                            }
                        }
                        
                        continuation.yield(AITokenEvent(
                            token: "",
                            isComplete: true,
                            tokenIndex: index,
                            elapsedMs: Date().timeIntervalSince(startTime) * 1000
                        ))
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                } else {
                    continuation.finish(throwing: AIError.noBackendAvailable)
                }
                #else
                continuation.finish(throwing: AIError.noBackendAvailable)
                #endif
            }
        }
    }
    
    private func buildFullPrompt(for request: AIRequest) -> String {
        var prompt = ""
        if let system = request.systemPrompt {
            prompt += "Instructions: \(system)\n\n"
        }
        
        if !request.retrievedContext.isEmpty {
            let context = request.retrievedContext.map { $0.text }.joined(separator: "\n")
            prompt += "Context:\n\(context)\n\n"
        }
        
        prompt += "User: \(request.userPrompt)"
        return prompt
    }

    
    func cancelCurrentGeneration() {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Need a new session context to cancel or reliance on standard Task cancellation
            // FoundationModels handles structured Task cancellation automatically
        }
        #endif
    }
    
    func healthCheck() async -> AIBackendHealth {
        let capability = checkCapability()
        if capability.canUseFoundationModels {
            return .healthy
        }
        if !capability.isAppleIntelligenceEnabled && capability.isAppleIntelligenceCapable {
            return .unavailable(reason: "Apple Intelligence is disabled in Settings")
        }
        return .unavailable(reason: "Apple Intelligence is not available on this device")
    }
}
