import Foundation

struct PerplexityDocumentBridge {
    
    /// Safely bridges internal DocumentChunks into AIRetrievedChunks for the Sonar API.
    /// Ensures we do not exceed the max token limit by approximating characters.
    static func bridgeChunks(chunks: [DocumentRetriever.DocumentChunk], maxTokens: Int = 100_000) -> [AIRetrievedChunk] {
        let maxChars = maxTokens * 4
        var currentChars = 0
        var result: [AIRetrievedChunk] = []
        
        for chunk in chunks {
            if currentChars + chunk.text.count <= maxChars {
                result.append(AIRetrievedChunk(
                    text: chunk.text,
                    sourceID: chunk.sourceID,
                    sourceName: "\(chunk.sourceName) (Page \(chunk.pageNumber ?? 1))",
                    relevanceScore: chunk.relevanceScore,
                    pageNumber: chunk.pageNumber
                ))
                currentChars += chunk.text.count
            } else {
                let remaining = maxChars - currentChars
                if remaining > 100 {
                    let truncated = String(chunk.text.prefix(remaining)) + "\n...[TRUNCATED DUE TO LENGTH LIMIT]"
                    result.append(AIRetrievedChunk(
                        text: truncated,
                        sourceID: chunk.sourceID,
                        sourceName: "\(chunk.sourceName) (Page \(chunk.pageNumber ?? 1))",
                        relevanceScore: chunk.relevanceScore,
                        pageNumber: chunk.pageNumber
                    ))
                }
                break // We've hit the limit
            }
        }
        
        return result
    }
}
