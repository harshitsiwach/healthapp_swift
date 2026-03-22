import Foundation

@MainActor
final class PerplexityHealthContextBridge {
    static let shared = PerplexityHealthContextBridge()
    private let insightsService = HealthInsightsService()
    
    private init() {}
    
    func buildHealthContextChunk() async -> AIRetrievedChunk? {
        await insightsService.refreshSummary()
        
        guard let summary = insightsService.lastSummary else {
            return nil
        }
        
        return AIRetrievedChunk(
            text: summary.aiContextString,
            sourceID: "apple_health_context",
            sourceName: "Apple Health Context",
            relevanceScore: 1.0,
            pageNumber: nil
        )
    }
    
    func buildHealthContext() async -> String {
        await insightsService.refreshSummary()
        return insightsService.lastSummary?.aiContextString ?? "No recent Apple Health data available."
    }
}
