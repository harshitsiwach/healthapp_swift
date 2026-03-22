import Foundation

@MainActor
final class PerplexityFoodAnalysisService: ObservableObject {
    static let shared = PerplexityFoodAnalysisService()
    private let orchestrator = AIOrchestrator()
    
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    
    private init() {}
    
    func analyzeMeal(image: Data?, description: String) async throws -> AIResponse {
        isAnalyzing = true
        defer { isAnalyzing = false }
        analysisError = nil
        
        do {
            var tags: [String] = []
            
            if image != nil {
                tags = ["hot meal", "restaurant food"] // Simulated local extraction
            }
            
            let prompt = PerplexityFoodVisionPromptBuilder.buildPrompt(
                foodDescription: description,
                localVisionTags: tags
            )
            
            let request = AIRequest(
                task: .perplexityFoodAnalysis,
                userPrompt: prompt,
                systemPrompt: "You are an expert nutritionist. Provide detailed, factual, web-grounded nutritional analysis of food descriptions. Do not give medical advice.",
                generationConfig: GenerationPreset.foodAnalysis.config
            )
            
            let response = try await orchestrator.generate(request)
            return response
        } catch {
            self.analysisError = error.localizedDescription
            throw error
        }
    }
}
