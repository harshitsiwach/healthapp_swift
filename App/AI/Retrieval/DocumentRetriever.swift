import Foundation
import Vision
import UIKit

// MARK: - Document Retriever

final class DocumentRetriever {
    
    struct DocumentChunk: Identifiable {
        let id = UUID()
        let text: String
        let sourceID: String
        let sourceName: String
        let pageNumber: Int?
        var relevanceScore: Double = 0
    }
    
    private var documentIndex: [DocumentChunk] = []
    
    // MARK: - Import & Index
    
    func importDocument(text: String, sourceName: String, sourceID: String? = nil) {
        let chunks = chunkText(text, sourceName: sourceName, sourceID: sourceID ?? UUID().uuidString)
        documentIndex.append(contentsOf: chunks)
    }
    
    func importOCRResult(image: UIImage, sourceName: String) async throws -> String {
        let ocrService = OCRService()
        let text = try await ocrService.recognizeText(in: image)
        importDocument(text: text, sourceName: sourceName)
        return text
    }
    
    // MARK: - Retrieval
    
    func retrieve(query: String, topK: Int = 5) -> [DocumentChunk] {
        // Simple keyword-based retrieval
        // In production, use embeddings or BM25
        let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))
        
        var scoredChunks = documentIndex.map { chunk -> DocumentChunk in
            var scored = chunk
            let chunkWords = Set(chunk.text.lowercased().split(separator: " ").map(String.init))
            let overlap = queryWords.intersection(chunkWords).count
            scored.relevanceScore = Double(overlap) / Double(max(queryWords.count, 1))
            return scored
        }
        
        scoredChunks.sort { $0.relevanceScore > $1.relevanceScore }
        return Array(scoredChunks.prefix(topK).filter { $0.relevanceScore > 0 })
    }
    
    func retrieveForPerplexity(query: String, maxTokens: Int = 100_000) -> [AIRetrievedChunk] {
        let chunks = retrieve(query: query, topK: 15) // Fetch more context for Perplexity
        return PerplexityDocumentBridge.bridgeChunks(chunks: chunks, maxTokens: maxTokens)
    }
    
    // MARK: - Chunking
    
    private func chunkText(
        _ text: String,
        sourceName: String,
        sourceID: String,
        chunkSize: Int = 500,
        overlap: Int = 50
    ) -> [DocumentChunk] {
        let words = text.split(separator: " ").map(String.init)
        var chunks: [DocumentChunk] = []
        var start = 0
        var pageEstimate = 1
        
        while start < words.count {
            let end = min(start + chunkSize, words.count)
            let chunkText = words[start..<end].joined(separator: " ")
            
            chunks.append(DocumentChunk(
                text: chunkText,
                sourceID: sourceID,
                sourceName: sourceName,
                pageNumber: pageEstimate
            ))
            
            start += chunkSize - overlap
            pageEstimate += 1
        }
        
        return chunks
    }
    
    // MARK: - Management
    
    func clearIndex() {
        documentIndex.removeAll()
    }
    
    var indexSize: Int {
        documentIndex.count
    }
}

// MARK: - OCR Service

final class OCRService {
    
    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw AIError.ocrFailure
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIError.ocrFailure)
            }
        }
    }
}
