import SwiftUI

@MainActor
class MealIdeasViewModel: ObservableObject {
    @Published var meals: [MealRecommendation] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let orchestrator = AIOrchestrator.shared
    private var debounceTask: Task<Void, Never>?
    
    func fetchMeals(
        remainingCalories: Int,
        goal: String,
        dietaryPreference: String,
        mealType: String,
        budget: String
    ) {
        // Cancel previous debounced request
        debounceTask?.cancel()
        
        debounceTask = Task {
            // Debounce: wait 500ms before making API call
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            isLoading = true
            error = nil
            
            do {
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
                
                let response = try await orchestrator.generate(request)
                
                guard !Task.isCancelled else { return }
                
                // Parse response
                let jsonString = extractJSON(from: response.text)
                if let data = jsonString.data(using: .utf8) {
                    meals = try JSONDecoder().decode([MealRecommendation].self, from: data)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let start = cleaned.firstIndex(where: { $0 == "[" }),
           let end = cleaned.lastIndex(where: { $0 == "]" }) {
            cleaned = String(cleaned[start...end])
        }
        
        return cleaned
    }
}
