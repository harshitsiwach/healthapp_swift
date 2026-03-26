import SwiftUI
import UIKit

@MainActor
class FoodLoggingViewModel: ObservableObject {
    
    enum State {
        case idle
        case analyzing
        case review
        case error(String)
    }
    
    @Published var state: State = .idle
    @Published var foodName: String = ""
    @Published var estimatedCalories: Int = 0
    @Published var proteinG: Double = 0
    @Published var carbsG: Double = 0
    @Published var fatG: Double = 0
    @Published var savedImagePath: String?
    @Published var activeBackendName: String?
    
    private let orchestrator = AIOrchestrator.shared
    
    func analyzeImage(_ image: UIImage) {
        state = .analyzing
        
        // Save image locally
        savedImagePath = saveImageLocally(image)
        
        Task {
            do {
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
                
                let request = AIRequest(
                    task: .foodAnalysis,
                    userPrompt: "Analyze this meal and estimate its nutritional content.",
                    systemPrompt: systemPrompt,
                    images: [imageInput],
                    generationConfig: GenerationPreset.foodAnalysis.config
                )
                
                let response = try await orchestrator.generate(request)
                let result = try parseFoodAnalysis(from: response.text)
                
                foodName = result.foodName
                estimatedCalories = result.estimatedCalories
                proteinG = result.proteinG
                carbsG = result.carbsG
                fatG = result.fatG
                activeBackendName = response.attribution.backendID == .appleFoundation ? "Apple Intelligence" : "Gemini"
                state = .review
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
    
    func analyzeText(_ text: String) {
        state = .analyzing
        
        Task {
            do {
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
                    userPrompt: "I ate: \(text). Estimate the nutritional content.",
                    systemPrompt: systemPrompt,
                    generationConfig: GenerationPreset.foodAnalysis.config
                )
                
                let response = try await orchestrator.generate(request)
                let result = try parseFoodAnalysis(from: response.text)
                
                foodName = result.foodName
                estimatedCalories = result.estimatedCalories
                proteinG = result.proteinG
                carbsG = result.carbsG
                fatG = result.fatG
                activeBackendName = response.attribution.backendID == .appleFoundation ? "Apple Intelligence" : "Gemini"
                state = .review
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
    
    private func parseFoodAnalysis(from text: String) throws -> FoodAnalysisResult {
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        if let start = cleaned.firstIndex(where: { $0 == "{" || $0 == "[" }),
           let end = cleaned.lastIndex(where: { $0 == "}" || $0 == "]" }) {
            cleaned = String(cleaned[start...end])
        } else {
            throw NSError(domain: "FoodLogging", code: 1, userInfo: [NSLocalizedDescriptionKey: "No JSON found in response:\n\(text)"])
        }
        
        guard let data = cleaned.data(using: .utf8) else {
            throw NSError(domain: "FoodLogging", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid text encoding"])
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(FoodAnalysisResult.self, from: data)
        } catch {
            throw NSError(domain: "FoodLogging", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to read standard format. Backend said:\n\(cleaned)"])
        }
    }
    
    private func saveImageLocally(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDir = docs.appendingPathComponent("MealImages")
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }
}
