import SwiftUI

struct GradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base background
            Color(colorScheme == .dark ? UIColor.systemGray6 : UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0))
                .ignoresSafeArea()
            
            // Gradient blobs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.3), Color.purple.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 80)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.25), Color.blue.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 150, y: 100)
                .blur(radius: 90)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.mint.opacity(0.2), Color.mint.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -50, y: 400)
                .blur(radius: 70)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.15), Color.orange.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: 120, y: -350)
                .blur(radius: 60)
        }
    }
}
