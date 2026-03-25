import Foundation
import SwiftUI

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

struct PerplexityTheme {
    // Colors
    static let background = Color(hex: "0D0D0D")     // Near Black
    static let surface = Color(hex: "1A1A1A")        // Dark Surface
    static let accent = Color(hex: "2DD4BF")         // Perplexity Teal
    static let accentSecondary = Color(hex: "38BDF8") // Sky Blue
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A1A1AA")  // Zinc 400
    static let border = Color.white.opacity(0.1)
    
    // Gradients
    static let brandGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Shapes
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
}

extension View {
    func perplexityHeadline() -> some View {
        self.font(.system(.title, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(PerplexityTheme.textPrimary)
    }
    
    func perplexitySubheadline() -> some View {
        self.font(.system(.subheadline, design: .rounded))
            .foregroundStyle(PerplexityTheme.textSecondary)
    }
}
