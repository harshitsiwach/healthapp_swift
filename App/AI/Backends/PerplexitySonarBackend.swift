import Foundation

final class PerplexitySonarBackend: AIBackend {
    var id: String { AIBackendID.perplexitySonar.rawValue }
    var displayName: String { "Perplexity Cloud" }
    var supportsVision: Bool { false }
    var supportsToolCalling: Bool { false }
    var maxContextWindow: Int? { 127_000 }
    
    private var currentTask: Task<Void, Never>?
    
    init() {}
    
    func prepare() async throws {
        let config = PerplexityConfig.shared
        guard config.isPerplexityEnabled else {
            throw PerplexityBackendError.disabledGlobally
        }
        guard PerplexityKeyStore.shared.hasKey else {
            throw PerplexityBackendError.missingAPIKey
        }
    }
    
    func warmup() async {
        // No-op for remote REST APIs
    }
    
    func healthCheck() async -> AIBackendHealth {
        let config = PerplexityConfig.shared
        guard config.isPerplexityEnabled else {
            return .unavailable(reason: "Perplexity disabled in settings")
        }
        guard PerplexityKeyStore.shared.hasKey else {
            return .unavailable(reason: "API key missing")
        }
        return .healthy
    }
    
    func cancelCurrentGeneration() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    func generate(_ request: AIRequest) async throws -> AIResponse {
        guard let key = PerplexityKeyStore.shared.getKey() else {
            throw PerplexityBackendError.missingAPIKey
        }
        
        let urlRequest = try buildRequest(for: request, apiKey: key, stream: false)
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let latency = Date().timeIntervalSince(startTime) * 1000
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PerplexityBackendError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw PerplexityBackendError.apiError(statusCode: httpResponse.statusCode, message: errorMsg)
        }
        
        let decoded = try JSONDecoder().decode(PerplexityCompletionResponse.self, from: data)
        let text = decoded.choices.first?.message.content ?? ""
        let citations = decoded.citations ?? []
        let usage = decoded.usage
        
        return AIResponse(
            text: text,
            attribution: AIBackendAttribution(
                backendID: .perplexitySonar,
                modelVersion: decoded.model ?? PerplexityConfig.shared.defaultChatModel,
                isOnDevice: false
            ),
            metadata: AIResponseMetadata(
                timeToFirstTokenMs: latency,
                totalLatencyMs: latency,
                tokensIn: usage?.prompt_tokens ?? 0,
                tokensOut: usage?.completion_tokens ?? 0,
                citations: citations
            )
        )
    }
    
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let key = PerplexityKeyStore.shared.getKey() else {
                        throw PerplexityBackendError.missingAPIKey
                    }
                    
                    let urlRequest = try self.buildRequest(for: request, apiKey: key, stream: true)
                    let (result, response) = try await URLSession.shared.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw PerplexityBackendError.invalidResponse
                    }
                    
                    if httpResponse.statusCode != 200 {
                        var errorData = Data()
                        for try await byte in result {
                            errorData.append(byte)
                        }
                        let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown Streaming Error"
                        throw PerplexityBackendError.apiError(statusCode: httpResponse.statusCode, message: errorMsg)
                    }
                    
                    var tokenIndex = 0
                    let startTime = Date()
                    
                    for try await line in result.lines {
                        guard !Task.isCancelled else { break }
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonStr = String(line.dropFirst(6))
                        guard jsonStr != "[DONE]" else { continue }
                        
                        guard let data = jsonStr.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(PerplexityStreamChunk.self, from: data),
                              let delta = chunk.choices.first?.delta.content else {
                            continue
                        }
                        
                        let elapsed = Date().timeIntervalSince(startTime) * 1000
                        
                        continuation.yield(AITokenEvent(
                            token: delta,
                            isComplete: chunk.choices.first?.finish_reason != nil,
                            tokenIndex: tokenIndex,
                            elapsedMs: elapsed
                        ))
                        tokenIndex += 1
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            self.currentTask = task
        }
    }
    
    // MARK: - Private Helpers
    
    private func buildRequest(for request: AIRequest, apiKey: String, stream: Bool) throws -> URLRequest {
        let url = PerplexityConfig.shared.apiBaseURL
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = request.generationConfig.timeoutSeconds
        
        var messages: [[String: Any]] = []
        if let sys = request.systemPrompt {
            messages.append(["role": "system", "content": sys])
        }
        
        // Include retrieved context
        var joinedContext = ""
        if !request.retrievedContext.isEmpty {
            joinedContext = request.retrievedContext.map { "--- Document Chunk: \($0.sourceName) ---\n\($0.text)" }.joined(separator: "\n\n")
            joinedContext += "\n\n"
        }
        
        messages.append(["role": "user", "content": joinedContext + request.userPrompt])
        
        let body: [String: Any] = [
            "model": PerplexityConfig.shared.defaultChatModel,
            "messages": messages,
            "max_tokens": request.generationConfig.maxOutputTokens,
            "temperature": request.generationConfig.temperature,
            "top_p": request.generationConfig.topP,
            "stream": stream
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        return urlRequest
    }
}

// MARK: - API Types

enum PerplexityBackendError: Error, LocalizedError {
    case disabledGlobally
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .disabledGlobally: return "Perplexity is disabled in settings."
        case .missingAPIKey: return "Perplexity API key is missing or invalid."
        case .invalidResponse: return "Received an invalid response from Perplexity API."
        case .apiError(let code, let msg): return "Perplexity API Error \(code): \(msg)"
        }
    }
}

struct PerplexityCompletionResponse: Codable {
    let id: String
    let model: String?
    let created: Int
    let choices: [Choice]
    let usage: Usage?
    let citations: [String]?
    
    struct Choice: Codable {
        let message: Message
        let index: Int
        let finish_reason: String?
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
}

struct PerplexityStreamChunk: Codable {
    let id: String
    let model: String?
    let choices: [Choice]
    let citations: [String]?
    
    struct Choice: Codable {
        let delta: Delta
        let index: Int
        let finish_reason: String?
    }
    
    struct Delta: Codable {
        let role: String?
        let content: String?
    }
}
