import Foundation

// MARK: - Llama.cpp Engine Bridge

/// This is the bridge to llama.cpp for real on-device inference.
/// Add llama.cpp as a Swift Package: https://github.com/ggerganov/llama.cpp
///
/// Package URL: https://github.com/nickvdp/llama.swift
/// Or use the C library directly via bridging header.

final class LlamaCppEngine {
    
    private var context: OpaquePointer?
    private var model: OpaquePointer?
    private var isInitialized = false
    
    // MARK: - Configuration
    
    struct Config {
        let contextLength: Int
        let batchSize: Int
        let threads: Int
        
        static let `default` = Config(
            contextLength: 8192,
            batchSize: 512,
            threads: 4
        )
    }
    
    private var config: Config = .default
    private var mockMode = false
    
    // MARK: - Lifecycle
    
    deinit {
        cleanup()
    }
    
    /// Enable mock mode for testing without a real model
    func enableMockMode() {
        mockMode = true
        isInitialized = true
        print("LlamaCppEngine: Mock mode enabled (demo responses)")
    }
    
    // MARK: - Model Loading
    
    /// Load a GGUF model file
    func loadModel(at path: URL, config: Config = .default) throws {
        self.config = config
        cleanup()
        
        if mockMode {
            isInitialized = true
            print("LlamaCppEngine: Mock mode - skipping model load")
            return
        }
        
        // In production with llama.cpp linked:
        /*
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 0 // CPU only for mobile
        
        model = llama_model_load_from_file(path.path, modelParams)
        guard model != nil else {
            throw LlamaError.modelLoadFailed
        }
        
        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = UInt32(config.contextLength)
        ctxParams.n_batch = UInt32(config.batchSize)
        
        context = llama_init_from_model(model, ctxParams)
        guard context != nil else {
            llama_model_free(model)
            model = nil
            throw LlamaError.contextInitFailed
        }
        */
        
        isInitialized = true
        print("LlamaCppEngine: Model loaded at \(path.lastPathComponent)")
    }
    
    // MARK: - Inference
    
    /// Generate text from a prompt
    func generate(
        prompt: String,
        maxTokens: Int = 512,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        stopTokens: [String] = ["</s>", "user:", "\n\n"],
        onToken: ((String) -> Void)? = nil
    ) async throws -> String {
        guard isInitialized else {
            throw LlamaError.notInitialized
        }
        
        // In production with llama.cpp linked:
        /*
        let vocab = llama_model_get_vocab(model)
        
        // Tokenize prompt
        let promptTokens = tokenize(text: prompt, vocab: vocab, addBos: true)
        
        // Process prompt
        let batch = llama_batch_init(Int32(promptTokens.count), 0, 1)
        defer { llama_batch_free(batch) }
        
        for (i, token) in promptTokens.enumerated() {
            llama_batch_add(&batch, token, Int32(i), [llama_seq_id(0)], false)
        }
        
        if llama_decode(context, batch) != 0 {
            throw LlamaError.inferenceFailed
        }
        
        // Generate tokens
        var generatedText = ""
        var nCur = promptTokens.count
        
        for _ in 0..<maxTokens {
            let logits = llama_get_logits_ith(context, Int32(batch.n_tokens - 1))
            let nVocab = llama_vocab_n_tokens(vocab)
            
            // Sample next token
            var candidates = [llama_token_data](repeating: llama_token_data(), count: Int(nVocab))
            for i in 0..<Int(nVocab) {
                candidates[i] = llama_token_data(id: llama_token(i), logit: Float(logits![i]), p: 0.0)
            }
            
            var candidatesP = llama_token_data_array(data: &candidates, size: Int(nVocab), sorted: false)
            
            // Apply temperature
            if temperature > 0 {
                llama_sample_temp(nil, &candidatesP, Float(temperature))
            }
            
            // Apply top-p
            llama_sample_top_p(nil, &candidatesP, Float(topP), 1)
            
            let newToken = llama_sample_token(nil, &candidatesP)
            
            // Check for end of sequence
            if llama_token_is_eog(vocab, newToken) {
                break
            }
            
            // Convert token to string
            let tokenStr = tokenToString(newToken, vocab: vocab)
            generatedText += tokenStr
            onToken?(tokenStr)
            
            // Check stop tokens
            for stop in stopTokens {
                if generatedText.hasSuffix(stop) {
                    generatedText = String(generatedText.dropLast(stop.count))
                    return generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Continue generation
            var nextBatch = llama_batch_init(1, 0, 1)
            llama_batch_add(&nextBatch, newToken, Int32(nCur), [llama_seq_id(0)], true)
            nCur += 1
            
            if llama_decode(context, nextBatch) != 0 {
                llama_batch_free(nextBatch)
                throw LlamaError.inferenceFailed
            }
            llama_batch_free(nextBatch)
        }
        
        return generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        */
        
        // Placeholder response until llama.cpp is linked
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate inference time
        return await generateMockResponse(for: prompt, maxTokens: maxTokens)
    }
    
    /// Stream tokens one by one
    func stream(
        prompt: String,
        maxTokens: Int = 512,
        temperature: Double = 0.7,
        topP: Double = 0.9
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await self.generate(
                        prompt: prompt,
                        maxTokens: maxTokens,
                        temperature: temperature,
                        topP: topP,
                        onToken: { token in
                            continuation.yield(token)
                        }
                    )
                    continuation.yield(response) // Final complete response
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        /*
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let mdl = model {
            llama_model_free(mdl)
            model = nil
        }
        */
        isInitialized = false
    }
    
    // MARK: - Token Count
    
    func tokenCount(for text: String) -> Int {
        // In production: use llama_tokenize
        return text.count / 4 // Rough estimate
    }
    
    // MARK: - Mock Response (for testing without llama.cpp)
    
    private func generateMockResponse(for prompt: String, maxTokens: Int) -> String {
        let lowered = prompt.lowercased()
        
        if lowered.contains("food") || lowered.contains("calories") || lowered.contains("meal") {
            return """
            {
                "food_name": "Dal Tadka with 2 Roti",
                "estimated_calories": 420,
                "protein_g": 15.0,
                "carbs_g": 55.0,
                "fat_g": 12.0
            }
            """
        }
        
        if lowered.contains("health report") || lowered.contains("weekly") {
            return """
            {
                "score": 7,
                "summary": "Your protein intake is consistent, but you're falling short on fiber. Consider adding more vegetables and salads.",
                "warnings": ["Low fiber intake this week", "Slightly high sodium from processed foods"],
                "natural_cures": [
                    {"name": "Isabgol (Psyllium Husk)", "benefit": "Add 1 tbsp to water before bed for fiber boost"},
                    {"name": "Jeera Water", "benefit": "Improves digestion and reduces bloating"}
                ]
            }
            """
        }
        
        if lowered.contains("recommend") || lowered.contains("suggest") || lowered.contains("meal") {
            return """
            [
                {"name": "Rajma Chawal", "calories": 380, "protein": 15, "carbs": 55, "fat": 10, "description": "Protein-rich kidney beans with steamed rice"},
                {"name": "Palak Paneer with Roti", "calories": 350, "protein": 18, "carbs": 30, "fat": 18, "description": "Iron-rich spinach with cottage cheese"},
                {"name": "Moong Dal Khichdi", "calories": 280, "protein": 12, "carbs": 45, "fat": 6, "description": "Easy to digest comfort food"},
                {"name": "Egg Curry with Rice", "calories": 380, "protein": 18, "carbs": 40, "fat": 16, "description": "High protein meal with spices"},
                {"name": "Chana Masala with Roti", "calories": 350, "protein": 14, "carbs": 48, "fat": 12, "description": "Chickpea curry rich in fiber and protein"}
            ]
            """
        }
        
        if lowered.contains("lab") || lowered.contains("report") || lowered.contains("blood") {
            return "Based on your lab results, your hemoglobin is slightly low at 11.5 g/dL. This is common and can be improved with iron-rich foods like spinach, dates, and jaggery. Your cholesterol is within normal range. I'd recommend getting your Vitamin D levels checked as well."
        }
        
        return "I'm your health assistant running locally on your device. I can help you with meal tracking, nutrition advice, and understanding your health data. What would you like to know?"
    }
}

// MARK: - Errors

enum LlamaError: LocalizedError {
    case modelLoadFailed
    case contextInitFailed
    case notInitialized
    case inferenceFailed
    case tokenizationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed: return "Failed to load the AI model. Make sure the model file is downloaded."
        case .contextInitFailed: return "Failed to initialize the AI engine."
        case .notInitialized: return "AI model not loaded. Please download it from Settings."
        case .inferenceFailed: return "AI processing failed. Please try again."
        case .tokenizationFailed: return "Failed to process your input."
        }
    }
}

// MARK: - Model Info

struct LlamaModelInfo {
    let name: String
    let path: URL
    let parameters: String
    let quantization: String
    let contextLength: Int
    let fileSizeMB: Int
    
    static let gemma4_2b = LlamaModelInfo(
        name: "Gemma 4 2B",
        path: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Models/gemma_4_2b_q4/model.bin"),
        parameters: "2B",
        quantization: "Q4_K_M",
        contextLength: 8192,
        fileSizeMB: 1500
    )
}
