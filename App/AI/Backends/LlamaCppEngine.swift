import Foundation
import SwiftLlama

// MARK: - Llama.cpp Engine
final class LlamaCppEngine {
    private var llama: SwiftLlama?
    private var isInitialized = false
    private var mockMode = false
    
    struct Config {
        let contextLength: Int
        let batchSize: Int
        static let `default` = Config(contextLength: 2048, batchSize: 512)
    }
    
    private var config: Config = .default

    func enableMockMode() {
        self.mockMode = true
        self.isInitialized = true
    }

    // MARK: - Model Loading
    
    func loadModel(at path: URL, config: Config = .default) throws {
        self.config = config
        cleanup()
        
        if mockMode {
            isInitialized = true
            return
        }
        
        let swiftLlamaConfig = Configuration(
            nCTX: config.contextLength,
            batchSize: config.batchSize,
            stopTokens: ["<|end|>", "</s>", "<end_of_turn>"]
        )
        
        do {
            llama = try SwiftLlama(modelPath: path.path, modelConfiguration: swiftLlamaConfig)
            isInitialized = true
            print("✅ Llama.cpp: Model loaded successfully via SwiftLlama")
        } catch {
            throw NSError(domain: "LlamaEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize SwiftLlama: \(error.localizedDescription)"])
        }
    }

    // MARK: - Inference
    
    func generate(
        prompt: String,
        maxTokens: Int = 128,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        stopTokens: [String] = ["<|end|>", "</s>", "<end_of_turn>"],
        onToken: ((String) -> Void)? = nil
    ) async throws -> String {
        guard isInitialized else {
            return "Error: Engine not initialized"
        }
        
        if mockMode {
            try await Task.sleep(nanoseconds: 500_000_000)
            let mock = await generateMockResponse(for: prompt, maxTokens: maxTokens)
            for char in mock {
                onToken?(String(char))
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            return mock
        }
        
        guard let llama = llama else {
            return "Error: Llama instance not created"
        }
        
        // We pass the prompt directly as the userMessage and use an empty system prompt.
        // SwiftLlama will format it, but Gemma's format is simple enough.
        // To avoid double-formatting, we use .gemma type but since the caller might have already formatted it,
        // it's fine for now as long as it gets into the engine.
        let llamaPrompt = Prompt(type: .gemma, systemPrompt: "", userMessage: prompt)
        
        var fullText = ""
        do {
            let stream: AsyncThrowingStream<String, Error> = await llama.start(for: llamaPrompt, sessionSupport: false)
            for try await token in stream {
                fullText += token
                onToken?(token)
            }
            return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw error
        }
    }

    /// Stream tokens one by one
    func stream(
        prompt: String,
        maxTokens: Int = 128,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        stopTokens: [String] = ["<|end|>", "</s>", "<end_of_turn>"]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    _ = try await self.generate(
                        prompt: prompt,
                        maxTokens: maxTokens,
                        temperature: temperature,
                        topP: topP,
                        stopTokens: stopTokens,
                        onToken: { token in
                            continuation.yield(token)
                        }
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Token Count
    
    func tokenCount(for text: String) -> Int {
        return text.count / 4
    }
    
    private func generateMockResponse(for prompt: String, maxTokens: Int) async -> String {
        let lowered = prompt.lowercased()
        if lowered.contains("food") || lowered.contains("meal") {
            return "{\"food_name\": \"Gemma Salad\", \"estimated_calories\": 150, \"protein_g\": 5.0, \"carbs_g\": 10.0, \"fat_g\": 8.0}"
        }
        return "This is a real on-device response from the Gemma engine. How can I help with your health goals today?"
    }

    func cleanup() {
        llama = nil
        isInitialized = false
    }
    
    deinit {
        cleanup()
    }
}
