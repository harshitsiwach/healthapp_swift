import Foundation

// MARK: - MedGemma Backend (Medical Specialist)

@MainActor
final class MedGemmaBackend: AIBackend {
    let id: String = "medgemma"
    let displayName: String = "MedGemma (Medical)"
    let supportsVision: Bool = false
    let supportsToolCalling: Bool = false
    let maxContextWindow: Int? = 8192
    
    private let modelStore: ModelStore
    private let engine = LlamaCppEngine()
    private var isReady: Bool = false
    
    init(modelStore: ModelStore? = nil) {
        self.modelStore = modelStore ?? ModelStore()
    }
    
    // MARK: - AIBackend Conformance
    
    func prepare() async throws {
        // Check if MedGemma model is installed
        if let manifest = modelStore.installedManifest,
           manifest.id.contains("medgemma"),
           let modelPath = manifest.localPath {
            let validator = ModelIntegrityValidator()
            let isValid = await validator.validate(manifest: manifest)
            guard isValid else { throw AIError.modelChecksumFailed }
            do {
                try engine.loadModel(at: modelPath, config: .default)
                isReady = true
            } catch {
                throw AIError.runtimeInitFailure(underlying: error)
            }
        } else {
            // No MedGemma model — use mock mode for testing
            engine.enableMockMode()
            isReady = true
        }
    }
    
    func warmup() async {
        guard isReady else { return }
        _ = try? await engine.generate(prompt: "Hello, I am a medical AI.", maxTokens: 5, temperature: 0.1)
    }
    
    func generate(_ request: AIRequest) async throws -> AIResponse {
        guard isReady else { throw AIError.modelMissing }
        
        let startTime = Date()
        let prompt = buildMedicalPrompt(for: request)
        
        let responseText = try await engine.generate(
            prompt: prompt,
            maxTokens: request.generationConfig.maxOutputTokens,
            temperature: request.generationConfig.temperature,
            topP: request.generationConfig.topP
        )
        
        let latency = Date().timeIntervalSince(startTime) * 1000
        
        return AIResponse(
            text: responseText,
            attribution: AIBackendAttribution(
                backendID: .medgemma,
                modelVersion: "medgemma-4b",
                isOnDevice: true
            ),
            metadata: AIResponseMetadata(
                timeToFirstTokenMs: latency * 0.3,
                totalLatencyMs: latency,
                tokensIn: engine.tokenCount(for: prompt),
                tokensOut: engine.tokenCount(for: responseText),
                wasCancelled: false,
                failureReason: nil
            )
        )
    }
    
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                guard self.isReady else {
                    continuation.finish(throwing: AIError.modelMissing)
                    return
                }
                
                let prompt = self.buildMedicalPrompt(for: request)
                let startTime = Date()
                var tokenIndex = 0
                
                do {
                    let stream = self.engine.stream(
                        prompt: prompt,
                        maxTokens: request.generationConfig.maxOutputTokens,
                        temperature: request.generationConfig.temperature,
                        topP: request.generationConfig.topP
                    )
                    
                    for try await token in stream {
                        let elapsed = Date().timeIntervalSince(startTime) * 1000
                        continuation.yield(AITokenEvent(
                            token: token,
                            isComplete: false,
                            tokenIndex: tokenIndex,
                            elapsedMs: elapsed
                        ))
                        tokenIndex += 1
                    }
                    
                    continuation.yield(AITokenEvent(
                        token: "",
                        isComplete: true,
                        tokenIndex: tokenIndex,
                        elapsedMs: Date().timeIntervalSince(startTime) * 1000
                    ))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func cancelCurrentGeneration() {}
    
    func healthCheck() async -> AIBackendHealth {
        if isReady { return .healthy }
        
        if let manifest = modelStore.installedManifest, manifest.id.contains("medgemma") {
            return .degraded(reason: "MedGemma installed but not initialized")
        }
        
        return .degraded(reason: "Running in demo mode (no MedGemma model)")
    }
    
    func unloadModel() {
        engine.cleanup()
        isReady = false
    }
    
    // MARK: - Medical Prompt Templates
    
    private func buildMedicalPrompt(for request: AIRequest) -> String {
        var prompt = ""
        
        // System prompt for medical context
        let medicalSystem = """
        You are MedGemma, a medical AI assistant developed by Google. You are running on-device in a health and nutrition app. Your role is to:
        - Analyze health data and lab reports
        - Provide nutrition and wellness guidance
        - Explain medical terms in simple language
        - Suggest when to consult a healthcare professional
        
        Important safety rules:
        - Always recommend consulting a doctor for serious symptoms
        - Never diagnose conditions or prescribe medications
        - Be clear about limitations
        - Use simple, non-technical language
        - When analyzing lab results, reference normal ranges
        """
        
        prompt += "<start_of_turn>system\n\(medicalSystem)<end_of_turn>\n"
        
        // Add context from retrieved documents
        if !request.retrievedContext.isEmpty {
            let contextText = request.retrievedContext.map { $0.text }.joined(separator: "\n")
            prompt += "<start_of_turn>context\nMedical context:\n\(contextText)<end_of_turn>\n"
        }
        
        // Task-specific instructions
        switch request.task {
        case .medicalDocQA:
            prompt += "<start_of_turn>system\nAnalyze this medical/lab report. Explain each value, flag anything outside normal ranges, and suggest next steps. Be specific about normal reference ranges.<end_of_turn>\n"
        case .nutritionSummary:
            prompt += "<start_of_turn>system\nProvide nutrition advice based on the user's health data. Consider Indian dietary patterns. Suggest specific foods with quantities.<end_of_turn>\n"
        case .reportSummary:
            prompt += "<start_of_turn>system\nSummarize this health report in simple terms. Highlight key findings and action items.<end_of_turn>\n"
        case .chat, .foodAnalysis, .structuredExtraction, .healthCaution, .ocrRewrite, .mealRecommendation, .weeklyReport:
            break
        }
        
        // User message
        prompt += "<start_of_turn>user\n\(request.userPrompt)<end_of_turn>\n"
        prompt += "<start_of_turn>model\n"
        
        return prompt
    }
}
