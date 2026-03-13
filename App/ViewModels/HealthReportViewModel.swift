import SwiftUI

@MainActor
class HealthReportViewModel: ObservableObject {
    @Published var report: HealthReportResult?
    @Published var isLoading = false
    @Published var error: String?
    
    private let gemini = GeminiService()
    
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
                report = try await gemini.generateWeeklyReport(
                    avgCalories: avgCalories,
                    avgProtein: avgProtein,
                    avgCarbs: avgCarbs,
                    avgFat: avgFat,
                    goalCompletionRate: goalCompletionRate,
                    userGoal: userGoal,
                    dietaryPreference: dietaryPreference
                )
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}
