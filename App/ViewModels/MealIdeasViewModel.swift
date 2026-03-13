import SwiftUI

@MainActor
class MealIdeasViewModel: ObservableObject {
    @Published var meals: [MealRecommendation] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let gemini = GeminiService()
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
                let result = try await gemini.getMealRecommendations(
                    remainingCalories: remainingCalories,
                    goal: goal,
                    dietaryPreference: dietaryPreference,
                    mealType: mealType,
                    budget: budget
                )
                
                guard !Task.isCancelled else { return }
                meals = result
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}
