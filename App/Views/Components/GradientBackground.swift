import SwiftUI

struct GradientBackground: View {
    var body: some View {
        ZStack {
            PerplexityTheme.background
                .ignoresSafeArea()
            
            // Subtle Teal Glow
            Circle()
                .fill(PerplexityTheme.accent.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -150, y: -300)
            
            // Subtle Sky Blue Glow
            Circle()
                .fill(PerplexityTheme.accentSecondary.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 100, y: 400)
        }
    }
}
