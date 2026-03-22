import Foundation

// MARK: - AI Backend Protocol

protocol AIBackend {
    var id: String { get }
    var displayName: String { get }
    var supportsVision: Bool { get }
    var supportsToolCalling: Bool { get }
    var maxContextWindow: Int? { get }
    
    func prepare() async throws
    func warmup() async
    func generate(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error>
    func cancelCurrentGeneration()
    func healthCheck() async -> AIBackendHealth
}

// MARK: - Backend Health

enum AIBackendHealth {
    case healthy
    case degraded(reason: String)
    case unavailable(reason: String)
}

// MARK: - Token Event

struct AITokenEvent: Sendable {
    let token: String
    let isComplete: Bool
    let tokenIndex: Int
    let elapsedMs: Double
}

// MARK: - Backend Identifier

enum AIBackendID: String, Codable {
    case appleFoundation = "apple_foundation"
    case qwenLocal = "qwen_local"
    case geminiRemote = "gemini_remote"
    case perplexitySonar = "perplexity_sonar"
}

// MARK: - Backend Attribution

struct AIBackendAttribution {
    let backendID: AIBackendID
    let modelVersion: String
    let isOnDevice: Bool
}
