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
            
            // Note: Since FoundationModels strictly supports string outputs via respond(to:) and streaming,
            // or specific @Generable schema for types, we will just pass the user prompt for standard tasks.
            
            let startTime = Date()
            
            let responseString: String
            
            let activeSession: LanguageModelSession
            if request.task != .chat {
                let system = request.systemPrompt ?? ""
                let instructions = request.task == .foodAnalysis ? "\(system)\nIMPORTANT: You must output ONLY RAW CONVENTIONAL JSON, with NO markdown, NO codeblocks, and NO conversational text." : system
                activeSession = LanguageModelSession { instructions }
                
                let response = try await activeSession.respond(to: request.userPrompt)
                responseString = response.content
            } else {
                let fullPrompt: String
                if let system = request.systemPrompt, !system.isEmpty {
                    fullPrompt = "\(system)\n\nUser request: \(request.userPrompt)"
                } else {
                    fullPrompt = request.userPrompt
                }
                
                let response = try await session.respond(to: fullPrompt)
                responseString = response.content
            }
            
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
                    timeToFirstTokenMs: latencyMs, // Approximate for non-streaming
                    totalLatencyMs: latencyMs,
                    tokensIn: 0, // Not explicitly tracked in simple response
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
                    
                    do {
                        let activeSession: LanguageModelSession
                        let promptToSend: String
                        
                        if request.task != .chat {
                            let system = request.systemPrompt ?? ""
                            let instructions = request.task == .foodAnalysis ? "\(system)\nIMPORTANT: You must output ONLY RAW CONVENTIONAL JSON, with NO markdown, NO codeblocks, and NO conversational text." : system
                            activeSession = LanguageModelSession { instructions }
                            promptToSend = request.userPrompt
                        } else {
                            activeSession = session
                            let fullPrompt: String
                            if let system = request.systemPrompt, !system.isEmpty {
                                fullPrompt = "\(system)\n\nUser request: \(request.userPrompt)"
                            } else {
                                fullPrompt = request.userPrompt
                            }
                            promptToSend = fullPrompt
                        }
                        
                        let stream = activeSession.streamResponse(to: promptToSend)
                        var index = 0
                        var lastContent = ""
                        
                        for try await snapshot in stream {
                            let fullContent = snapshot.content
                            // Calculate delta
                            let delta = String(fullContent.suffix(fullContent.count - lastContent.count))
                            
                            if !delta.isEmpty {
                                continuation.yield(AITokenEvent(
                                    token: delta,
                                    isComplete: false,
                                    tokenIndex: index,
                                    elapsedMs: 0
                                ))
                                index += 1
                                lastContent = fullContent
                            }
                        }
                        // Send final completion event
                        continuation.yield(AITokenEvent(
                            token: "",
                            isComplete: true,
                            tokenIndex: index,
                            elapsedMs: 0
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
