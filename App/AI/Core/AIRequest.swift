import Foundation
import UIKit

// MARK: - AI Task

enum AITask: String, Codable {
    case chat
    case nutritionSummary
    case foodAnalysis
    case medicalDocQA
    case reportSummary
    case structuredExtraction
    case healthCaution
    case ocrRewrite
    case mealRecommendation
    case weeklyReport
    case perplexityHealthQA
    case perplexityFoodAnalysis
    case perplexityTrendSummary
    case perplexityReportExplain
    case perplexityCitedNutrition
    case perplexityMedicalSearch
}

// MARK: - AI Request

struct AIRequest {
    let task: AITask
    let systemPrompt: String?
    let userPrompt: String
    let images: [AIImageInput]
    let retrievedContext: [AIRetrievedChunk]
    let generationConfig: GenerationConfig
    let tools: [AIToolDefinition]
    let outputSchema: AIOutputSchema?
    let conversationID: String?
    
    init(
        task: AITask,
        userPrompt: String,
        systemPrompt: String? = nil,
        images: [AIImageInput] = [],
        retrievedContext: [AIRetrievedChunk] = [],
        generationConfig: GenerationConfig = .default,
        tools: [AIToolDefinition] = [],
        outputSchema: AIOutputSchema? = nil,
        conversationID: String? = nil
    ) {
        self.task = task
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        self.images = images
        self.retrievedContext = retrievedContext
        self.generationConfig = generationConfig
        self.tools = tools
        self.outputSchema = outputSchema
        self.conversationID = conversationID
    }
}

// MARK: - Image Input

struct AIImageInput {
    let imageData: Data
    let mimeType: String
    
    init(image: UIImage, compressionQuality: CGFloat = 0.8) {
        self.imageData = image.jpegData(compressionQuality: compressionQuality) ?? Data()
        self.mimeType = "image/jpeg"
    }
    
    init(data: Data, mimeType: String = "image/jpeg") {
        self.imageData = data
        self.mimeType = mimeType
    }
    
    var base64Encoded: String {
        imageData.base64EncodedString()
    }
}

// MARK: - Retrieved Chunk

struct AIRetrievedChunk {
    let text: String
    let sourceID: String
    let sourceName: String
    let relevanceScore: Double
    let pageNumber: Int?
}

// MARK: - Tool Definition

struct AIToolDefinition {
    let name: String
    let description: String
    let parameters: [String: Any]
}

// MARK: - Output Schema

struct AIOutputSchema {
    let format: String // "json"
    let schema: String // JSON Schema string
}
