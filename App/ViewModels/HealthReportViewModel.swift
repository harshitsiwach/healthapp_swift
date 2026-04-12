import SwiftUI

@MainActor
class HealthReportViewModel: ObservableObject {
    @Published var report: HealthReportResult?
    @Published var isLoading = false
    @Published var error: String?
    
    private let orchestrator = AIOrchestrator()
    
    func generate(
        avgCalories: Int,
        avgProtein: Double,
        avgCarbs: Double,
        avgFat: Double,
        goalCompletionRate: Double,
        userGoal: String,
        dietaryPreference: String
    ) {
        isLoading = true
        error = nil
        
        Task {
            do {
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
                
                let response = try await orchestrator.generate(request)
                report = try parseHealthReport(from: response.text)
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func parseHealthReport(from text: String) throws -> HealthReportResult {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.invalidResponse
        }
        return try JSONDecoder().decode(HealthReportResult.self, from: data)
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let start = cleaned.firstIndex(where: { $0 == "{" }),
           let end = cleaned.lastIndex(where: { $0 == "}" }) {
            cleaned = String(cleaned[start...end])
        }
        
        return cleaned
    }
}
