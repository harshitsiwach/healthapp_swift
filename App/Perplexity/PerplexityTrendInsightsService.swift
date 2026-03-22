import Foundation
import Combine

@MainActor
public final class PerplexityTrendInsightsService: ObservableObject {
    public static let shared = PerplexityTrendInsightsService()
    
    @Published public var currentInsight: String?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let orchestrator = AIOrchestrator()
    
    private init() {}
    
    public func generateWeeklyInsight() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real application, we would use HealthDataRepository to fetch true weekly aggregates.
            // Using placeholder logic to demonstrate the AI integration point.
            let currentWeekText = "Avg steps: 8500, Avg sleep: 6.5h, Avg calories: 2100"
            let previousWeekText = "Avg steps: 6000, Avg sleep: 7.0h, Avg calories: 2300"
            
            let prompt = PerplexityTrendPromptBuilder.buildPrompt(
                currentWeekText: currentWeekText, 
                previousWeekText: previousWeekText
            )
            
            let request = AIRequest(
                task: .perplexityTrendSummary,
                userPrompt: prompt,
                systemPrompt: "You are an encouraging health AI coach analyzing trend data. Keep it strictly motivational and factual based strictly on the metrics provided.",
                generationConfig: GenerationPreset.fastChat.config
            )
            
            let response = try await orchestrator.generate(request)
            self.currentInsight = response.text
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
