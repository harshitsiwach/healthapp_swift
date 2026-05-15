import Foundation

// MARK: - AI Response

struct AIResponse {
    let text: String
    let structuredOutput: [String: Any]?
    let attribution: AIBackendAttribution
    let metadata: AIResponseMetadata
    let evidenceChunks: [AIRetrievedChunk]
    
    init(
        text: String,
        structuredOutput: [String: Any]? = nil,
        attribution: AIBackendAttribution,
        metadata: AIResponseMetadata = .empty,
        evidenceChunks: [AIRetrievedChunk] = []
    ) {
        self.text = text
        self.structuredOutput = structuredOutput
        self.attribution = attribution
        self.metadata = metadata
        self.evidenceChunks = evidenceChunks
    }
}

// MARK: - Response Metadata

struct AIResponseMetadata {
    let timeToFirstTokenMs: Double
    let totalLatencyMs: Double
    let tokensIn: Int
    let tokensOut: Int
    let wasCancelled: Bool
    let failureReason: String?
    
    static let empty = AIResponseMetadata(
        timeToFirstTokenMs: 0,
        totalLatencyMs: 0,
        tokensIn: 0,
        tokensOut: 0,
        wasCancelled: false,
        failureReason: nil
    )
}

// MARK: - AI Error

enum AIError: LocalizedError {
    case noBackendAvailable
    case modelMissing
    case modelChecksumFailed
    case insufficientStorage
    case warmupTimeout
    case runtimeInitFailure(underlying: Error?)
    case inferenceCancelled
    case memoryPressure
    case ocrFailure
    case retrievalEmpty
    case unsupportedFileType
    case networkError(underlying: Error?)
    case invalidResponse
    case safetyTriggered(category: String)
    
    var errorDescription: String? {
        switch self {
        case .noBackendAvailable:
            return "No AI backend is currently available. Please check your settings."
        case .modelMissing:
            return "The AI model hasn't been downloaded yet. Go to Settings to install it."
        case .modelChecksumFailed:
            return "Model file verification failed. Please re-download."
        case .insufficientStorage:
            return "Not enough storage space for the AI model."
        case .warmupTimeout:
            return "The AI model took too long to initialize. Please try again."
        case .runtimeInitFailure:
            return "Failed to start the AI engine. Please restart the app."
        case .inferenceCancelled:
            return "Generation was cancelled."
        case .memoryPressure:
            return "Low memory. The AI model was unloaded. Please try again."
        case .ocrFailure:
            return "Failed to read text from the document."
        case .retrievalEmpty:
            return "No relevant information found in your documents."
        case .unsupportedFileType:
            return "This file type is not supported."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .invalidResponse:
            return "Received an unexpected response. Please try again."
        case .safetyTriggered(let category):
            return "For your safety, we can't provide advice on \(category). Please consult a healthcare professional."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .warmupTimeout, .memoryPressure, .networkError, .invalidResponse:
            return true
        default:
            return false
        }
    }
}
