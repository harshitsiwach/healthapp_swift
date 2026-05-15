import Foundation
import UIKit

// MARK: - Gemini Service (Remote Backend + Feature API)

final class GeminiService: AIBackend {
    let id: String = "gemini_remote"
    let displayName: String = "Gemini 2.5 Flash"
    let supportsVision: Bool = true
    let supportsToolCalling: Bool = true
    let maxContextWindow: Int? = nil
    
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-2.5-flash"
    private var currentTask: Task<Void, Never>?
    
    init(apiKey: String = GeminiConfig.apiKey) {
        self.apiKey = apiKey
    }
    
    // MARK: - AIBackend Conformance
    
    func prepare() async throws {
        // Verify API key is set
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            throw AIError.noBackendAvailable
        }
    }
    
    func warmup() async {
        // No warmup needed for cloud API
    }
    
    func generate(_ request: AIRequest) async throws -> AIResponse {
        let startTime = Date()
        
        // Check for internet
        guard await isNetworkAvailable() else {
            throw AIError.networkError(underlying: nil)
        }
        
        let requestBody = buildRequestBody(for: request)
        let data = try await makeAPICall(body: requestBody)
        let text = try parseResponse(data: data)
        
        let latency = Date().timeIntervalSince(startTime) * 1000
        
        return AIResponse(
            text: text,
            attribution: AIBackendAttribution(
                backendID: .gemmaLocal,
                modelVersion: model,
                isOnDevice: false
            ),
            metadata: AIResponseMetadata(
                timeToFirstTokenMs: latency,
                totalLatencyMs: latency,
                tokensIn: request.userPrompt.count / 4,
                tokensOut: text.count / 4,
                wasCancelled: false,
                failureReason: nil
            )
        )
    }
    
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error> {
        AsyncThrowingStream { continuation in
            currentTask = Task {
                do {
                    let response = try await generate(request)
                    // Simulate streaming for the remote response
                    let words = response.text.split(separator: " ")
                    for (index, word) in words.enumerated() {
                        if Task.isCancelled { break }
                        let isLast = index == words.count - 1
                        continuation.yield(AITokenEvent(
                            token: String(word) + (isLast ? "" : " "),
                            isComplete: isLast,
                            tokenIndex: index,
                            elapsedMs: Double(index) * 20
                        ))
                        try? await Task.sleep(nanoseconds: 20_000_000)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func cancelCurrentGeneration() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    func healthCheck() async -> AIBackendHealth {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            return .unavailable(reason: "API key not configured")
        }
        return .healthy
    }
    
    // MARK: - Food Analysis
    
    func analyzeFoodImage(_ image: UIImage, additionalContext: String = "") async throws -> FoodAnalysisResult {
        let imageInput = AIImageInput(image: image)
        
        let systemPrompt = """
        You are an expert Indian nutritionist with deep knowledge of Indian cuisine, street food, and home-cooked meals.
        Analyze the food in the image and provide accurate nutritional estimates.
        Always respond in valid JSON format with this exact structure:
        {
            "food_name": "Name of the dish",
            "estimated_calories": 350,
            "protein_g": 15.0,
            "carbs_g": 45.0,
            "fat_g": 12.0
        }
        Be specific with Indian dish names (e.g., "Paneer Butter Masala with 2 Roti" not just "Indian curry").
        Estimate portions based on a typical adult serving.
        """
        
        let userPrompt = additionalContext.isEmpty
            ? "Analyze this meal and estimate its nutritional content."
            : "Analyze this meal: \(additionalContext). Estimate its nutritional content."
        
        let request = AIRequest(
            task: .foodAnalysis,
            userPrompt: userPrompt,
            systemPrompt: systemPrompt,
            images: [imageInput],
            generationConfig: GenerationPreset.foodAnalysis.config
        )
        
        let response = try await generate(request)
        return try parseFoodAnalysis(from: response.text)
    }
    
    // MARK: - Food Text Analysis
    
    func analyzeFoodText(_ description: String) async throws -> FoodAnalysisResult {
        let systemPrompt = """
        You are an expert Indian nutritionist. The user describes what they ate.
        Estimate calories, protein, carbs, and fat for the described meal.
        Always respond in valid JSON format:
        {
            "food_name": "Descriptive name of the meal",
            "estimated_calories": 350,
            "protein_g": 15.0,
            "carbs_g": 45.0,
            "fat_g": 12.0
        }
        Use common Indian portion sizes. Be specific and accurate.
        """
        
        let request = AIRequest(
            task: .foodAnalysis,
            userPrompt: "I ate: \(description). Estimate the nutritional content.",
            systemPrompt: systemPrompt,
            generationConfig: GenerationPreset.foodAnalysis.config
        )
        
        let response = try await generate(request)
        return try parseFoodAnalysis(from: response.text)
    }
    
    // MARK: - Weekly Health Report
    
    func generateWeeklyReport(
        avgCalories: Int,
        avgProtein: Double,
        avgCarbs: Double,
        avgFat: Double,
        goalCompletionRate: Double,
        userGoal: String,
        dietaryPreference: String
    ) async throws -> HealthReportResult {
        let systemPrompt = """
        You are expert health advisor specializing in Indian wellness and Ayurvedic remedies.
        Analyze the user's weekly nutrition data and provide a health report.
        Respond in valid JSON:
        {
            "score": 7,
            "summary": "Two sentences summarizing overall health this week.",
            "warnings": ["Warning 1 if any", "Warning 2 if any"],
            "natural_cures": [
                {"name": "Jeera Water", "benefit": "Improves digestion and metabolism"},
                {"name": "Turmeric Milk", "benefit": "Anti-inflammatory, boosts immunity"}
            ]
        }
        Score is 1-10. Warnings should be specific to their data. Natural cures should be Indian Ayurvedic remedies relevant to their deficiencies.
        """
        
        let userPrompt = """
        My weekly averages:
        - Calories: \(avgCalories)/day
        - Protein: \(String(format: "%.1f", avgProtein))g/day
        - Carbs: \(String(format: "%.1f", avgCarbs))g/day
        - Fat: \(String(format: "%.1f", avgFat))g/day
        - Goal completion rate: \(Int(goalCompletionRate * 100))%
        - My goal: \(userGoal)
        - Diet: \(dietaryPreference)
        
        Generate my weekly health report.
        """
        
        let request = AIRequest(
            task: .weeklyReport,
            userPrompt: userPrompt,
            systemPrompt: systemPrompt,
            generationConfig: GenerationPreset.nutritionSummary.config
        )
        
        let response = try await generate(request)
        return try parseHealthReport(from: response.text)
    }
    
    // MARK: - Meal Recommendations
    
    func getMealRecommendations(
        remainingCalories: Int,
        goal: String,
        dietaryPreference: String,
        mealType: String,
        budget: String
    ) async throws -> [MealRecommendation] {
        let systemPrompt = """
        You are a creative Indian chef and nutritionist. Suggest culturally appropriate Indian meals.
        Respond in valid JSON array:
        [
            {
                "name": "Dal Tadka with Brown Rice",
                "calories": 450,
                "protein": 18.0,
                "carbs": 60.0,
                "fat": 12.0,
                "description": "A comforting lentil dish tempered with cumin and garlic, served with fiber-rich brown rice."
            }
        ]
        Suggest exactly 5 meals. Consider the user's budget, dietary preference, and remaining caloric budget.
        """
        
        let userPrompt = """
        Remaining calories for today: \(remainingCalories) kcal
        Goal: \(goal)
        Diet: \(dietaryPreference)
        Meal type: \(mealType)
        Budget: \(budget)
        
        Suggest 5 culturally appropriate Indian meals.
        """
        
        let request = AIRequest(
            task: .mealRecommendation,
            userPrompt: userPrompt,
            systemPrompt: systemPrompt,
            generationConfig: GenerationPreset.mealRecommendation.config
        )
        
        let response = try await generate(request)
        return try parseMealRecommendations(from: response.text)
    }
    
    // MARK: - Private Helpers
    
    private func isNetworkAvailable() async -> Bool {
        // Simple network check
        return true // In production, use Network framework or reachability
    }
    
    private func buildRequestBody(for request: AIRequest) -> [String: Any] {
        var parts: [[String: Any]] = []
        
        // Add images
        for image in request.images {
            parts.append([
                "inline_data": [
                    "mime_type": image.mimeType,
                    "data": image.base64Encoded
                ]
            ])
        }
        
        // Add text
        parts.append(["text": request.userPrompt])
        
        var contents: [[String: Any]] = []
        
        // System instruction
        if let systemPrompt = request.systemPrompt {
            contents.append([
                "role": "user",
                "parts": [["text": systemPrompt]]
            ])
            contents.append([
                "role": "model",
                "parts": [["text": "Understood. I will follow these instructions."]]
            ])
        }
        
        contents.append([
            "role": "user",
            "parts": parts
        ])
        
        var body: [String: Any] = ["contents": contents]
        
        body["generationConfig"] = [
            "temperature": request.generationConfig.temperature,
            "maxOutputTokens": request.generationConfig.maxOutputTokens,
            "topP": request.generationConfig.topP
        ]
        
        return body
    }
    
    private func makeAPICall(body: [String: Any]) async throws -> Data {
        let urlString = "\(baseURL)/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIError.networkError(underlying: nil)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        urlRequest.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.networkError(underlying: nil)
        }
        
        return data
    }
    
    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIError.invalidResponse
        }
        return text
    }
    
    private func parseFoodAnalysis(from text: String) throws -> FoodAnalysisResult {
        // Extract JSON from possible markdown code blocks
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        return try JSONDecoder().decode(FoodAnalysisResult.self, from: data)
    }
    
    private func parseHealthReport(from text: String) throws -> HealthReportResult {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        return try JSONDecoder().decode(HealthReportResult.self, from: data)
    }
    
    private func parseMealRecommendations(from text: String) throws -> [MealRecommendation] {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        
        return try JSONDecoder().decode([MealRecommendation].self, from: data)
    }
    
    private func extractJSON(from text: String) -> String {
        // Handle markdown code blocks
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find first { or [ and last } or ]
        if let start = cleaned.firstIndex(where: { $0 == "{" || $0 == "[" }),
           let end = cleaned.lastIndex(where: { $0 == "}" || $0 == "]" }) {
            cleaned = String(cleaned[start...end])
        }
        
        return cleaned
    }
}

// MARK: - Legacy Response Types (defined in ViewModels)

struct HealthReportResult: Codable {
    let score: Int
    let summary: String
    let warnings: [String]
    let naturalCures: [NaturalCure]
    
    enum CodingKeys: String, CodingKey {
        case score, summary, warnings
        case naturalCures = "natural_cures"
    }
}

struct NaturalCure: Codable {
    let name: String
    let benefit: String
}

struct MealRecommendation: Codable, Identifiable {
    var id: String { name }
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let description: String
}

// MARK: - Config

struct GeminiConfig {
    static var apiKey: String {
        // TODO: Replace with your Gemini API key
        // In production, use Keychain or environment variable
        return "YOUR_GEMINI_API_KEY_HERE"
    }
}
