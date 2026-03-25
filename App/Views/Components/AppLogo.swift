import SwiftUI

/// A premium branding component for Perplexity Health using SF Symbols and teal gradients
struct AppLogo: View {
    enum Size {
        case small, medium, large, hero
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 40
            case .large: return 60
            case .hero: return 100
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 12
            case .hero: return 24
            }
        }
    }
    
    var size: Size = .medium
    var showText: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glass Base
                Circle()
                    .fill(PerplexityTheme.surface.opacity(0.8))
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Perplexity Style Icon (Stylized P / Affinity)
                Image(systemName: "search.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [PerplexityTheme.accent, PerplexityTheme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.iconSize, height: size.iconSize)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .frame(width: size.iconSize + size.padding * 2, height: size.iconSize + size.padding * 2)
            
            if showText {
                HStack(spacing: 4) {
                    Text("Perplexity")
                        .fontWeight(.black)
                    Text("Health")
                        .fontWeight(.light)
                        .foregroundStyle(PerplexityTheme.accent)
                }
                .font(.system(size: size.iconSize * 0.45, design: .rounded))
                .foregroundStyle(PerplexityTheme.textPrimary)
            }
        }
    }
}

// MARK: - Perplexity Search Bar

struct PerplexitySearchBar: View {
    var placeholder: String = "Ask Perplexity about your health..."
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkle")
                    .foregroundStyle(PerplexityTheme.brandGradient)
                    .font(.system(size: 18, weight: .bold))
                
                Text(placeholder)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(PerplexityTheme.textSecondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PerplexityTheme.textSecondary.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PerplexityTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(PerplexityTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        PerplexityTheme.background.ignoresSafeArea()
        VStack(spacing: 40) {
            AppLogo(size: .hero, showText: true)
            PerplexitySearchBar(action: {})
                .padding()
        }
    }
}
