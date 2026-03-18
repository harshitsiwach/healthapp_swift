import SwiftUI

/// A premium branding component for HealthApp using SF Symbols and glassmorphism
struct AppLogo: View {
    enum Size {
        case small, medium, large, hero
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 40
            case .large: return 60
            case .hero: return 120
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 12
            case .large: return 20
            case .hero: return 40
            }
        }
    }
    
    var size: Size = .medium
    var showText: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.iconSize * 1.5
                        )
                    )
                    .blur(radius: 10)
                
                // Glass Base
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear, .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Icon Stack
                ZStack {
                    Image(systemName: "bolt.heart.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                        .frame(width: size.iconSize, height: size.iconSize)
                    
                    Image(systemName: "sparkles")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.yellow)
                        .frame(width: size.iconSize * 0.4, height: size.iconSize * 0.4)
                        .offset(x: size.iconSize * 0.4, y: -size.iconSize * 0.4)
                        .symbolEffect(.variableColor.reversing, options: .repeating)
                }
            }
            .frame(width: size.iconSize + size.padding * 2, height: size.iconSize + size.padding * 2)
            
            if showText {
                Text("HealthApp")
                    .font(.system(size: size.iconSize * 0.5, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            AppLogo(size: .hero, showText: true)
            HStack(spacing: 20) {
                AppLogo(size: .large)
                AppLogo(size: .medium)
                AppLogo(size: .small)
            }
        }
    }
}
