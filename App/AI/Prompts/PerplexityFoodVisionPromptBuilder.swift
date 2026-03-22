import Foundation

public struct PerplexityFoodVisionPromptBuilder {
    public static func buildPrompt(foodDescription: String, localVisionTags: [String]) -> String {
        let tagsLine = localVisionTags.isEmpty ? "None" : localVisionTags.joined(separator: ", ")
        return """
        Please analyze the nutritional content of the following meal.
        
        User's description: "\(foodDescription)"
        Automatically detected visual tags: \(tagsLine)
        
        Your response must include:
        1. A brief health verdict on this meal (is it balanced, high protein, high carb, etc.?).
        2. Estimated total macronutrients: Calories (kcal), Carbohydrates (g), Proteins (g), and Fats (g).
        3. A short breakdown of the main ingredients and their individual contributions.
        
        IMPORTANT: End your response by citing reliable databases or sources you used to provide these estimates.
        """
    }
}
