import Foundation

struct PerplexityConfig {
    static let shared = PerplexityConfig()
    
    var isPerplexityEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isPerplexityEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isPerplexityEnabled") }
    }
    
    // API Setup
    let apiBaseURL: URL = URL(string: "https://api.perplexity.ai/chat/completions")!
    
    // Model Options
    let defaultChatModel: String = "sonar-pro"
    let defaultReasoningModel: String = "sonar-reasoning"
    
    private init() {}
}
