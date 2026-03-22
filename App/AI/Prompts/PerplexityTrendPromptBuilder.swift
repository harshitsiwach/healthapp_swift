import Foundation

public struct PerplexityTrendPromptBuilder {
    public static func buildPrompt(currentWeekText: String, previousWeekText: String) -> String {
        return """
        Please analyze the user's health trends based on the following weekly aggregates.
        
        Previous 7 Days:
        \(previousWeekText)
        
        Last 7 Days (Current):
        \(currentWeekText)
        
        Provide a concise, 2-3 sentence motivational insight comparing these two periods. Highlight improvements or gently suggest where to focus. Do not provide medical advice.
        """
    }
}
