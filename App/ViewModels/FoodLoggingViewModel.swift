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
    
    private let gemini = GeminiService()
    
    func analyzeImage(_ image: UIImage) {
        state = .analyzing
        
        // Save image locally
        savedImagePath = saveImageLocally(image)
        
        Task {
            do {
                let result = try await gemini.analyzeFoodImage(image)
                foodName = result.foodName
                estimatedCalories = result.estimatedCalories
                proteinG = result.proteinG
                carbsG = result.carbsG
                fatG = result.fatG
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
                let result = try await gemini.analyzeFoodText(text)
                foodName = result.foodName
                estimatedCalories = result.estimatedCalories
                proteinG = result.proteinG
                carbsG = result.carbsG
                fatG = result.fatG
                state = .review
            } catch {
                state = .error(error.localizedDescription)
            }
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
